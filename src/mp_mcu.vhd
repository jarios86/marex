library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.numeric_std_unsigned.all;
use work.mp_mcu_pkg.all;
use work.mp_rcu_pkg.all;
use work.mp_global_pkg.all;
use work.mp_ocu_pkg.all;

entity mp_mcu is
	port(
		clk           : in  std_logic;
		rst_n         : in  std_logic;
		pumping_clk   : in  std_logic;
		cmd           : in  mcu_command;
		input_data    : in  std_logic_vector(AXI_INTERFACE_BIT_WIDTH - 1 downto 0);
		req_comp_step : out std_logic;
		req_finish    : out std_logic
	);
end entity mp_mcu;

architecture RTL of mp_mcu is

	type state is (idle, wait_cmd, pump, feed_rcus, collect_objs, comp_step, finish, config_goc, config_rcus);
	signal r_mp_mcu_control_state, n_mp_mcu_control_state : state;

	signal r_ocb, n_ocb : OCB;

	signal r_ocb_to_rcu, n_ocb_to_rcu       : from_ocb_if_array;
	signal n_rcu_to_ocb                     : to_ocb_if_array;
	signal r_ecu_config_id, n_ecu_config_id : std_logic_vector(NUM_ECUs_PER_RCU_BIT_WITDH-1 downto 0);
	signal n_rcu_cmd                        : rcu_command_array;
	signal n_busy                           : std_logic_array;

	signal n_goc_in            : obj_parameters;
	signal n_goc_out           : obj_parameters;
	signal n_goc_wr            : std_logic;
	signal n_goc_rd            : std_logic;
	signal n_goc_req_comp_step : std_logic;
	signal n_goc_req_finish    : std_logic;

	signal r_collect_state_counter, n_collect_state_counter : std_logic_vector(RCU_EXECUTION_CICLES_BITS_WIDTH - 1 downto 0);

	signal r_goc_config, n_goc_config : obj_parameters;
	signal r_rcu_config, n_rcu_config : from_ocb_if;
	signal r_rcu_idx, n_rcu_idx       : std_logic_vector(MAX_NUM_RULES_BIT_WIDTH - 1 downto 0);

begin

	mp_rcu_maker : for idx in 0 to (MAX_NUM_RULES - 1) generate
	begin
		mp_rcu_inst : entity work.mp_rcu
			port map(
				clk            => clk,
				rst_n          => rst_n,
				ocb_in_if      => n_ocb_to_rcu(idx),
				cmd            => n_rcu_cmd(idx),
				ecu_config_idx => r_ecu_config_id,
				ocb_out_if     => n_rcu_to_ocb(idx),
				busy           => n_busy(idx)
			);
	end generate;

	goc_inst : entity work.mp_goc
		port map(
			clk           => clk,
			rst_n         => rst_n,
			ocb_in_if     => n_goc_in,
			ocb_out_if    => n_goc_out,
			read          => n_goc_rd,
			write         => n_goc_wr,
			req_finish    => n_goc_req_finish,
			req_comp_step => n_goc_req_comp_step
		);

	process(clk, rst_n)
	begin
		if (rst_n = '0') then
			r_mp_mcu_control_state  <= idle;
			r_collect_state_counter <= std_logic_vector(to_unsigned(RCU_EXECUTION_CICLES - 1, r_collect_state_counter'length));
			r_goc_config            <= (others => (others => '0'));
			r_rcu_config            <= (others => (others => '0'));
			r_rcu_idx               <= (others => '0');
			r_ecu_config_id			<= (others => '0');
			r_ocb					<= (others => (others => (others => '0')));
			r_ocb_to_rcu			<= (others => (others => (others => '0')));

		elsif rising_edge(clk) then
			r_mp_mcu_control_state  <= n_mp_mcu_control_state;
			r_collect_state_counter <= n_collect_state_counter;
			r_goc_config            <= n_goc_config;
			r_rcu_config            <= n_rcu_config;
			r_rcu_idx               <= n_rcu_idx;
			r_ecu_config_id			<= n_ecu_config_id;
			r_ocb_to_rcu			<= n_ocb_to_rcu;
			r_ocb					<= n_ocb;
--			for idx in 0 to (MAX_NUM_RULES - 1) loop
--				r_ocb(idx) 			<= n_ocb(idx);
--				r_ocb_to_rcu(idx)	<= n_ocb_to_rcu(idx);
--			end loop;

		end if;
	end process;

	process(ALL)
	begin
		n_mp_mcu_control_state  <= r_mp_mcu_control_state;
		n_goc_rd                <= '0';
		n_goc_wr                <= '0';
		n_goc_in                <= (others => (others => '0'));
		n_collect_state_counter <= r_collect_state_counter;
		n_ocb_to_rcu            <= r_ocb_to_rcu;
		n_goc_config            <= r_goc_config;
		n_rcu_config			<= r_rcu_config;
		n_ecu_config_id			<= r_ecu_config_id;
		n_rcu_idx				<= r_rcu_idx;
		n_ocb					<= r_ocb;
		n_rcu_cmd				<= (others=>NOP);
--		for idx in 0 to (MAX_NUM_RULES - 1) loop
--			n_ocb(idx)     <= r_ocb(idx);
--			n_rcu_cmd(idx) <= NOP;
--		end loop;

		case (r_mp_mcu_control_state) is
			when idle =>
				n_mp_mcu_control_state <= wait_cmd;

			when wait_cmd =>
				if (cmd = START) then
					n_mp_mcu_control_state <= pump;
				elsif (cmd = CONFIG and input_data(CONFIG_UNIT_BIT_IDX downto CONFIG_DATA_BIT_IDX + 1) = x"1") then
					n_mp_mcu_control_state <= config_goc;
				elsif (cmd = CONFIG and input_data(CONFIG_UNIT_BIT_IDX downto CONFIG_DATA_BIT_IDX + 1) = x"2") then
					n_mp_mcu_control_state <= config_rcus;
					n_ecu_config_id		   <= (others => '0');
					n_rcu_idx			   <= (others => '0');
				end if;

			when pump =>
				if (n_goc_req_finish = '1') then
					n_mp_mcu_control_state <= finish;
				elsif (n_goc_req_comp_step = '1') then
					n_mp_mcu_control_state <= comp_step;
				else
					if (pumping_clk = '1') then
						n_goc_rd <= '1';
						n_ocb(0) <= n_goc_out;
						if(n_ocb(MAX_NUM_RULES - 1).object /= std_logic_vector(to_unsigned(special_object_types'pos(NL), NUM_OBJECT_TYPES_BIT_WIDTH))) then
							n_goc_wr <= '1';
							n_goc_in <= n_ocb(MAX_NUM_RULES - 1);							
						end if;
						n_mp_mcu_control_state <= feed_rcus;
						for ocb_idx in (MAX_NUM_RULES - 1) downto 1 loop
							n_ocb(ocb_idx) <= r_ocb(ocb_idx - 1);
							-- Shift probability register
							n_ocb(ocb_idx).probability <= r_ocb(ocb_idx - 1).probability(PROBABILITY_BIT_WIDTH-2 downto 0) & r_ocb(ocb_idx - 1).probability(PROBABILITY_BIT_WIDTH-1);
						end loop;
					end if;
				end if;

			when feed_rcus =>
				for idx in 0 to (MAX_NUM_RULES - 1) loop
					--TODO debería de comprobar la señal de busy de la rcu antes de mandarle un comando?
					n_ocb_to_rcu(idx).object          <= r_ocb(idx).object;
					n_ocb_to_rcu(idx).num_active_objs <= r_ocb(idx).active_objs;
					n_ocb_to_rcu(idx).probability     <= r_ocb(idx).probability;
					n_rcu_cmd(idx)                    <= EXECUTE;
				end loop;
				n_mp_mcu_control_state <= collect_objs;

			when collect_objs =>
				if (or r_collect_state_counter = '0') then
					n_mp_mcu_control_state  <= pump;
					n_collect_state_counter <= std_logic_vector(to_unsigned(RCU_EXECUTION_CICLES - 1, r_collect_state_counter'length));
				else
					n_collect_state_counter <= r_collect_state_counter - 1;
					for idx in 0 to (MAX_NUM_RULES - 1) loop
						if (n_rcu_to_ocb(idx).obj_active = '1') then
							if (n_rcu_to_ocb(idx).purge = '1') then
								n_ocb(idx).active_objs <= r_ocb(idx).active_objs + n_rcu_to_ocb(idx).num_active_objs;
							else
								n_ocb(idx).active_objs <= r_ocb(idx).active_objs - n_rcu_to_ocb(idx).num_active_objs;
							end if;
						end if;
						if (n_rcu_to_ocb(idx).obj_queue = '1') then
							n_ocb(idx).queued_objs <= r_ocb(idx).queued_objs + n_rcu_to_ocb(idx).num_queued_objs;
						end if;
					end loop;
				end if;

			when comp_step =>
				if (n_goc_req_finish = '1') then
					n_mp_mcu_control_state <= finish;

				else                    --if(n_goc_req_comp_step = '0') then
					n_mp_mcu_control_state <= pump;
				end if;

			when finish =>
				n_mp_mcu_control_state <= wait_cmd;

			when config_goc =>
				if (input_data(CONFIG_PARAM_BIT_IDX downto CONFIG_UNIT_BIT_IDX + 1) = x"0") then
					n_goc_config.object <= input_data(n_goc_in.object'length - 1 downto 0);

				elsif (input_data(CONFIG_PARAM_BIT_IDX downto CONFIG_UNIT_BIT_IDX + 1) = x"1") then
					n_goc_config.active_objs <= input_data(n_goc_in.active_objs'length - 1 downto 0);

				elsif (input_data(CONFIG_PARAM_BIT_IDX downto CONFIG_UNIT_BIT_IDX + 1) = x"2") then
					n_goc_config.queued_objs <= input_data(n_goc_in.queued_objs'length - 1 downto 0);
				else
					n_goc_in             <= r_goc_config;
					n_goc_in.probability <= input_data(n_goc_in.probability'length - 1 downto 0);
					n_goc_wr             <= '1';
				end if;

				if (input_data(CONFIG_LAST_DATA_BIT_IDX) = '1') then
					n_mp_mcu_control_state <= wait_cmd;
				end if;

			when config_rcus =>
				if (input_data(CONFIG_PARAM_BIT_IDX downto CONFIG_UNIT_BIT_IDX + 1) = x"5") then -- Rule Computation Limit
					n_ocb_to_rcu(to_integer(r_rcu_idx)).num_active_objs <= input_data(MAX_NUM_OBJECTS_PER_TYPE_BIT_WIDTH-1 downto 0);
					n_rcu_cmd(to_integer(r_rcu_idx)) 					<= CONFIG_LIMIT;
					
				elsif (input_data(CONFIG_PARAM_BIT_IDX downto CONFIG_UNIT_BIT_IDX + 1) = x"0") then -- OCU Object type
					n_rcu_config.object <= input_data(NUM_OBJECT_TYPES_BIT_WIDTH-1 downto 0);
					
				elsif (input_data(CONFIG_PARAM_BIT_IDX downto CONFIG_UNIT_BIT_IDX + 1) = x"4") then -- OCU Reference
					n_rcu_config.num_active_objs <= input_data(MAX_NUM_OBJECTS_PER_TYPE_BIT_WIDTH-1 downto 0);
					
				elsif (input_data(CONFIG_PARAM_BIT_IDX downto CONFIG_UNIT_BIT_IDX + 1) = x"3") then -- OCU Probability
					n_ocb_to_rcu(to_integer(r_rcu_idx))				<= r_rcu_config;
					n_ocb_to_rcu(to_integer(r_rcu_idx)).probability	<= input_data(PROBABILITY_BIT_WIDTH-1 downto 0);
					n_rcu_cmd(to_integer(r_rcu_idx)) 				<= CONFIGURE;
					if(r_ecu_config_id = std_logic_vector(to_unsigned(MAX_NUM_ECU_OPERANDS_PER_RCU+MAX_NUM_ECU_RESULTS_PER_RCU-1, r_ecu_config_id'length))) then
						n_ecu_config_id <= (others=>'0');
						if(r_rcu_idx = std_logic_vector(to_unsigned(MAX_NUM_RULES-1, r_rcu_idx'length))) then
							n_rcu_idx <= (others=>'0');
							n_mp_mcu_control_state <= wait_cmd;
						else
							n_rcu_idx <= r_rcu_idx + 1;
						end if;
						report "RCU_" & to_hstring(r_rcu_idx) & " configured";
					else
						n_ecu_config_id	<= r_ecu_config_id + 1;
					end if;
				end if;

				if (input_data(CONFIG_LAST_DATA_BIT_IDX) = '1') then
					n_mp_mcu_control_state <= wait_cmd;
				end if;

		end case;
	end process;

	process(ALL)
	begin
		req_comp_step <= n_goc_req_comp_step;
		req_finish    <= n_goc_req_finish;
	end process;
end architecture RTL;
