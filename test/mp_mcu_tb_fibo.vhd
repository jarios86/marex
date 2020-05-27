library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.mp_global_pkg.all;
use work.mp_mcu_pkg.all;
use work.mp_rcu_pkg.all;

entity mp_mcu_tb_fibo is
end entity mp_mcu_tb_fibo;

architecture RTL of mp_mcu_tb_fibo is
	
	constant period : time := 20 ns;
	
	signal clk : std_logic;
	signal rst_n : std_logic;
	signal pumping_clk : std_logic;
	signal cmd : mcu_command;
	signal req_comp_step : std_logic;
	signal req_finish : std_logic;
	signal input_data : std_logic_vector(AXI_INTERFACE_BIT_WIDTH-1 downto 0);
	
	type object_type 		is (NL, ALFA, OMEGA, DELTA, A40, A21, A11, A1, A20, A2, A30, A31); -- El número de object_types debe coincidir con la constante MAX_NUM_OBJECTS_TYPES
	type integer_array 		is array (0 to NUM_OBJECT_TYPES-1) of integer;
	
	signal objects_GOC		: integer_array := (object_type'pos(ALFA), object_type'pos(A40), object_type'pos(A21), object_type'pos(A11), object_type'pos(A1), object_type'pos(A20), object_type'pos(A2), 
		object_type'pos(A30), object_type'pos(A31), object_type'pos(OMEGA)
	);
	signal active_GOC		: integer_array := (0, 1, 0, 1, 0, 1, 0, 0, 1, 0);
	signal queued_GOC		: integer_array := (0, 0, 0, 0, 0, 0, 0, 0, 0, 0);
	signal probability_GOC	: integer_array := (0, 1, 1, 1, 1, 1, 1, 1, 1, 1);
	
	type rcu_integer_array 		is array (0 to MAX_NUM_RULES-1) of integer;
	-- Active RCUs
	signal rcu_limits			: rcu_integer_array := (100, 100, 100, 100, 100, 100, 0, 0);	
	
	signal objects_RCU_0		: rcu_integer_array := (object_type'pos(A11), object_type'pos(NL), object_type'pos(NL), object_type'pos(NL), object_type'pos(A1), object_type'pos(A30));
	signal reference_RCU_0		: rcu_integer_array := (1, 0, 0, 0, 1, 1);
	signal probability_RCU_0	: rcu_integer_array := (255, 0, 0, 0, 0, 0);
	
	signal objects_RCU_1		: rcu_integer_array := (object_type'pos(A20), object_type'pos(NL), object_type'pos(NL), object_type'pos(NL), object_type'pos(A21), object_type'pos(A30));
	signal reference_RCU_1		: rcu_integer_array := (1, 0, 0, 0, 1, 1);
	signal probability_RCU_1	: rcu_integer_array := (255, 0, 0, 0, 0, 0);
	
	signal objects_RCU_2		: rcu_integer_array := (object_type'pos(A21), object_type'pos(NL), object_type'pos(NL), object_type'pos(NL), object_type'pos(A2), object_type'pos(A40));
	signal reference_RCU_2		: rcu_integer_array := (1, 0, 0, 0, 1, 1, 0);
	signal probability_RCU_2	: rcu_integer_array := (255, 0, 0, 0, 0, 0, 0);
	
	signal objects_RCU_3		: rcu_integer_array := (object_type'pos(A30), object_type'pos(NL), object_type'pos(NL), object_type'pos(NL), object_type'pos(A31), object_type'pos(A40));
	signal reference_RCU_3		: rcu_integer_array := (1, 0, 0, 0, 1, 1, 0);
	signal probability_RCU_3	: rcu_integer_array := (255, 0, 0, 0, 0, 0, 0);
	
	signal objects_RCU_4		: rcu_integer_array := (object_type'pos(A31), object_type'pos(NL), object_type'pos(NL), object_type'pos(NL), object_type'pos(NL), object_type'pos(NL));
	signal reference_RCU_4		: rcu_integer_array := (1, 0, 0, 0, 0, 0, 0);
	signal probability_RCU_4	: rcu_integer_array := (255, 0, 0, 0, 0, 0, 0);
	
	signal objects_RCU_5		: rcu_integer_array := (object_type'pos(A40), object_type'pos(NL), object_type'pos(NL), object_type'pos(NL), object_type'pos(NL), object_type'pos(NL));
	signal reference_RCU_5		: rcu_integer_array := (1, 0, 0, 0, 0, 0, 0);
	signal probability_RCU_5	: rcu_integer_array := (255, 0, 0, 0, 0, 0, 0);
	
	-- NULL RCU	
	signal objects_RCU_NL		: rcu_integer_array := (object_type'pos(NL), object_type'pos(NL), object_type'pos(NL), object_type'pos(NL),	object_type'pos(NL), object_type'pos(NL), object_type'pos(NL));
	signal reference_RCU_NL		: rcu_integer_array := (0, 0, 0, 0, 0, 0, 0);
	signal probability_RCU_NL	: rcu_integer_array := (0, 0, 0, 0, 0, 0, 0);

begin

	clock_driver : process
	begin
		clk <= '1';
		wait for period / 2;
		clk <= '0';
		wait for period / 2;
	end process clock_driver;
	
	pumping_clock_driver : process
	begin
		pumping_clk <= '1';
		wait for 4 * period / 2;
		pumping_clk <= '0';
		wait for 4 * period / 2;
	end process pumping_clock_driver;
	
	
	inst : entity work.mp_mcu
		port map(
			clk           => clk,
			rst_n         => rst_n,
			pumping_clk   => pumping_clk,
			cmd           => cmd,
			input_data 	  => input_data,
			req_comp_step => req_comp_step,
			req_finish    => req_finish
		);

	stim_proc : process
		variable rcu_idx : integer := 0;
	begin
		-- hold reset state.
		wait for period;
		rst_n <= '0';
		wait for period;
		rst_n <= '1';
		wait for period;
		
		-- insert stimulus here
		cmd 		<= CONFIG;
		input_data 	<= (others=>'0');
		input_data(CONFIG_UNIT_BIT_IDX downto CONFIG_DATA_BIT_IDX+1) <= "01";
		wait for period;
		
		for idx in 0 to (objects_GOC'length-1) loop
			input_data 	<= (others=>'0');
			input_data(CONFIG_DATA_BIT_IDX downto 0)  					 	<= (16-1 downto NUM_OBJECT_TYPES_BIT_WIDTH => '0') & std_logic_vector(to_unsigned(objects_GOC(idx), NUM_OBJECT_TYPES_BIT_WIDTH));
			input_data(CONFIG_UNIT_BIT_IDX downto CONFIG_DATA_BIT_IDX+1) 	<= "01";
			input_data(CONFIG_PARAM_BIT_IDX downto CONFIG_UNIT_BIT_IDX+1) 	<= "000";
			wait for period;
			
			input_data 	<= (others=>'0');
			input_data(CONFIG_DATA_BIT_IDX downto 0)  						<= std_logic_vector(to_unsigned(active_GOC(idx), MAX_NUM_OBJECTS_PER_TYPE));
			input_data(CONFIG_UNIT_BIT_IDX downto CONFIG_DATA_BIT_IDX+1) 	<= "01";
			input_data(CONFIG_PARAM_BIT_IDX downto CONFIG_UNIT_BIT_IDX+1) 	<= "001";
			wait for period;
			
			input_data 	<= (others=>'0');
			input_data(CONFIG_DATA_BIT_IDX downto 0)  						<= std_logic_vector(to_unsigned(queued_GOC(idx), MAX_NUM_OBJECTS_PER_TYPE));
			input_data(CONFIG_UNIT_BIT_IDX downto CONFIG_DATA_BIT_IDX+1) 	<= "01";
			input_data(CONFIG_PARAM_BIT_IDX downto CONFIG_UNIT_BIT_IDX+1) 	<= "010";
			wait for period;
			
			input_data 	<= (others=>'0');
			input_data(CONFIG_DATA_BIT_IDX downto 0)  						<= std_logic_vector(to_unsigned(probability_GOC(idx), MAX_NUM_OBJECTS_PER_TYPE));
			input_data(CONFIG_UNIT_BIT_IDX downto CONFIG_DATA_BIT_IDX+1)	<= "01";
			input_data(CONFIG_PARAM_BIT_IDX downto CONFIG_UNIT_BIT_IDX+1)	<= "011";
			if(idx = objects_GOC'length-1) then
				input_data(CONFIG_LAST_DATA_BIT_IDX) <= '1';
			end if;
			wait for period;
		end loop;		
		cmd 		<= NOP;
		wait for period;
		
		cmd 		<= CONFIG;
		input_data 	<= (others=>'0');
		input_data(CONFIG_UNIT_BIT_IDX downto CONFIG_DATA_BIT_IDX+1) <= "10";
		wait for period;
		for rcu_idx in 0 to (MAX_NUM_RULES-1) loop
			case rcu_idx is
				when 0 =>
					input_data 	<= (others=>'0');
					input_data(CONFIG_DATA_BIT_IDX downto 0)  						<= std_logic_vector(to_unsigned(rcu_limits(0), CONFIG_DATA_BIT_IDX+1));
					input_data(CONFIG_UNIT_BIT_IDX downto CONFIG_DATA_BIT_IDX+1) 	<= "10";
					input_data(CONFIG_PARAM_BIT_IDX downto CONFIG_UNIT_BIT_IDX+1) 	<= "101";
					wait for period;
					
					for ocu_idx in 0 to (MAX_NUM_ECU_OPERANDS_PER_RCU+MAX_NUM_ECU_RESULTS_PER_RCU-1) loop
						input_data 	<= (others=>'0');
						input_data(CONFIG_DATA_BIT_IDX downto 0)  						<= std_logic_vector(to_unsigned(objects_RCU_0(ocu_idx), CONFIG_DATA_BIT_IDX+1));
						input_data(CONFIG_UNIT_BIT_IDX downto CONFIG_DATA_BIT_IDX+1) 	<= "10";
						input_data(CONFIG_PARAM_BIT_IDX downto CONFIG_UNIT_BIT_IDX+1) 	<= "000";
						wait for period;
						
						input_data 	<= (others=>'0');
						input_data(CONFIG_DATA_BIT_IDX downto 0)  						<= std_logic_vector(to_unsigned(reference_RCU_0(ocu_idx), CONFIG_DATA_BIT_IDX+1));
						input_data(CONFIG_UNIT_BIT_IDX downto CONFIG_DATA_BIT_IDX+1) 	<= "10";
						input_data(CONFIG_PARAM_BIT_IDX downto CONFIG_UNIT_BIT_IDX+1) 	<= "100";
						wait for period;
						
						input_data 	<= (others=>'0');
						input_data(CONFIG_DATA_BIT_IDX downto 0)  						<= std_logic_vector(to_unsigned(probability_RCU_0(ocu_idx), CONFIG_DATA_BIT_IDX+1));
						input_data(CONFIG_UNIT_BIT_IDX downto CONFIG_DATA_BIT_IDX+1) 	<= "10";
						input_data(CONFIG_PARAM_BIT_IDX downto CONFIG_UNIT_BIT_IDX+1) 	<= "011";
						wait for period;
					end loop;
					
				when 1 =>
					input_data 	<= (others=>'0');
					input_data(CONFIG_DATA_BIT_IDX downto 0)  						<= std_logic_vector(to_unsigned(rcu_limits(1), CONFIG_DATA_BIT_IDX+1));
					input_data(CONFIG_UNIT_BIT_IDX downto CONFIG_DATA_BIT_IDX+1) 	<= "10";
					input_data(CONFIG_PARAM_BIT_IDX downto CONFIG_UNIT_BIT_IDX+1) 	<= "101";
					wait for period;
					
					for ocu_idx in 0 to (MAX_NUM_ECU_OPERANDS_PER_RCU+MAX_NUM_ECU_RESULTS_PER_RCU-1) loop
						input_data 	<= (others=>'0');
						input_data(CONFIG_DATA_BIT_IDX downto 0)  						<= std_logic_vector(to_unsigned(objects_RCU_1(ocu_idx), CONFIG_DATA_BIT_IDX+1));
						input_data(CONFIG_UNIT_BIT_IDX downto CONFIG_DATA_BIT_IDX+1) 	<= "10";
						input_data(CONFIG_PARAM_BIT_IDX downto CONFIG_UNIT_BIT_IDX+1) 	<= "000";
						wait for period;
						
						input_data 	<= (others=>'0');
						input_data(CONFIG_DATA_BIT_IDX downto 0)  						<= std_logic_vector(to_unsigned(reference_RCU_1(ocu_idx), CONFIG_DATA_BIT_IDX+1));
						input_data(CONFIG_UNIT_BIT_IDX downto CONFIG_DATA_BIT_IDX+1) 	<= "10";
						input_data(CONFIG_PARAM_BIT_IDX downto CONFIG_UNIT_BIT_IDX+1) 	<= "100";
						wait for period;
						
						input_data 	<= (others=>'0');
						input_data(CONFIG_DATA_BIT_IDX downto 0)  						<= std_logic_vector(to_unsigned(probability_RCU_1(ocu_idx), CONFIG_DATA_BIT_IDX+1));
						input_data(CONFIG_UNIT_BIT_IDX downto CONFIG_DATA_BIT_IDX+1) 	<= "10";
						input_data(CONFIG_PARAM_BIT_IDX downto CONFIG_UNIT_BIT_IDX+1) 	<= "011";
						wait for period;
					end loop;
					
				when 2 =>
					input_data 	<= (others=>'0');
					input_data(CONFIG_DATA_BIT_IDX downto 0)  						<= std_logic_vector(to_unsigned(rcu_limits(2), CONFIG_DATA_BIT_IDX+1));
					input_data(CONFIG_UNIT_BIT_IDX downto CONFIG_DATA_BIT_IDX+1) 	<= "10";
					input_data(CONFIG_PARAM_BIT_IDX downto CONFIG_UNIT_BIT_IDX+1) 	<= "101";
					wait for period;
					
					for ocu_idx in 0 to (MAX_NUM_ECU_OPERANDS_PER_RCU+MAX_NUM_ECU_RESULTS_PER_RCU-1) loop
						input_data 	<= (others=>'0');
						input_data(CONFIG_DATA_BIT_IDX downto 0)  						<= std_logic_vector(to_unsigned(objects_RCU_2(ocu_idx), CONFIG_DATA_BIT_IDX+1));
						input_data(CONFIG_UNIT_BIT_IDX downto CONFIG_DATA_BIT_IDX+1) 	<= "10";
						input_data(CONFIG_PARAM_BIT_IDX downto CONFIG_UNIT_BIT_IDX+1) 	<= "000";
						wait for period;
						
						input_data 	<= (others=>'0');
						input_data(CONFIG_DATA_BIT_IDX downto 0)  						<= std_logic_vector(to_unsigned(reference_RCU_2(ocu_idx), CONFIG_DATA_BIT_IDX+1));
						input_data(CONFIG_UNIT_BIT_IDX downto CONFIG_DATA_BIT_IDX+1) 	<= "10";
						input_data(CONFIG_PARAM_BIT_IDX downto CONFIG_UNIT_BIT_IDX+1) 	<= "100";
						wait for period;
						
						input_data 	<= (others=>'0');
						input_data(CONFIG_DATA_BIT_IDX downto 0)  						<= std_logic_vector(to_unsigned(probability_RCU_2(ocu_idx), CONFIG_DATA_BIT_IDX+1));
						input_data(CONFIG_UNIT_BIT_IDX downto CONFIG_DATA_BIT_IDX+1) 	<= "10";
						input_data(CONFIG_PARAM_BIT_IDX downto CONFIG_UNIT_BIT_IDX+1) 	<= "011";
						wait for period;
					end loop;
					
				when 3 =>
					input_data 	<= (others=>'0');
					input_data(CONFIG_DATA_BIT_IDX downto 0)  						<= std_logic_vector(to_unsigned(rcu_limits(3), CONFIG_DATA_BIT_IDX+1));
					input_data(CONFIG_UNIT_BIT_IDX downto CONFIG_DATA_BIT_IDX+1) 	<= "10";
					input_data(CONFIG_PARAM_BIT_IDX downto CONFIG_UNIT_BIT_IDX+1) 	<= "101";
					wait for period;
					
					for ocu_idx in 0 to (MAX_NUM_ECU_OPERANDS_PER_RCU+MAX_NUM_ECU_RESULTS_PER_RCU-1) loop
						input_data 	<= (others=>'0');
						input_data(CONFIG_DATA_BIT_IDX downto 0)  						<= std_logic_vector(to_unsigned(objects_RCU_3(ocu_idx), CONFIG_DATA_BIT_IDX+1));
						input_data(CONFIG_UNIT_BIT_IDX downto CONFIG_DATA_BIT_IDX+1) 	<= "10";
						input_data(CONFIG_PARAM_BIT_IDX downto CONFIG_UNIT_BIT_IDX+1) 	<= "000";
						wait for period;
						
						input_data 	<= (others=>'0');
						input_data(CONFIG_DATA_BIT_IDX downto 0)  						<= std_logic_vector(to_unsigned(reference_RCU_3(ocu_idx), CONFIG_DATA_BIT_IDX+1));
						input_data(CONFIG_UNIT_BIT_IDX downto CONFIG_DATA_BIT_IDX+1) 	<= "10";
						input_data(CONFIG_PARAM_BIT_IDX downto CONFIG_UNIT_BIT_IDX+1) 	<= "100";
						wait for period;
						
						input_data 	<= (others=>'0');
						input_data(CONFIG_DATA_BIT_IDX downto 0)  						<= std_logic_vector(to_unsigned(probability_RCU_3(ocu_idx), CONFIG_DATA_BIT_IDX+1));
						input_data(CONFIG_UNIT_BIT_IDX downto CONFIG_DATA_BIT_IDX+1) 	<= "10";
						input_data(CONFIG_PARAM_BIT_IDX downto CONFIG_UNIT_BIT_IDX+1) 	<= "011";
						wait for period;
					end loop;
					
				when 4 =>
					input_data 	<= (others=>'0');
					input_data(CONFIG_DATA_BIT_IDX downto 0)  						<= std_logic_vector(to_unsigned(rcu_limits(4), CONFIG_DATA_BIT_IDX+1));
					input_data(CONFIG_UNIT_BIT_IDX downto CONFIG_DATA_BIT_IDX+1) 	<= "10";
					input_data(CONFIG_PARAM_BIT_IDX downto CONFIG_UNIT_BIT_IDX+1) 	<= "101";
					wait for period;
					
					for ocu_idx in 0 to (MAX_NUM_ECU_OPERANDS_PER_RCU+MAX_NUM_ECU_RESULTS_PER_RCU-1) loop
						input_data 	<= (others=>'0');
						input_data(CONFIG_DATA_BIT_IDX downto 0)  						<= std_logic_vector(to_unsigned(objects_RCU_4(ocu_idx), CONFIG_DATA_BIT_IDX+1));
						input_data(CONFIG_UNIT_BIT_IDX downto CONFIG_DATA_BIT_IDX+1) 	<= "10";
						input_data(CONFIG_PARAM_BIT_IDX downto CONFIG_UNIT_BIT_IDX+1) 	<= "000";
						wait for period;
						
						input_data 	<= (others=>'0');
						input_data(CONFIG_DATA_BIT_IDX downto 0)  						<= std_logic_vector(to_unsigned(reference_RCU_4(ocu_idx), CONFIG_DATA_BIT_IDX+1));
						input_data(CONFIG_UNIT_BIT_IDX downto CONFIG_DATA_BIT_IDX+1) 	<= "10";
						input_data(CONFIG_PARAM_BIT_IDX downto CONFIG_UNIT_BIT_IDX+1) 	<= "100";
						wait for period;
						
						input_data 	<= (others=>'0');
						input_data(CONFIG_DATA_BIT_IDX downto 0)  						<= std_logic_vector(to_unsigned(probability_RCU_4(ocu_idx), CONFIG_DATA_BIT_IDX+1));
						input_data(CONFIG_UNIT_BIT_IDX downto CONFIG_DATA_BIT_IDX+1) 	<= "10";
						input_data(CONFIG_PARAM_BIT_IDX downto CONFIG_UNIT_BIT_IDX+1) 	<= "011";
						wait for period;
					end loop;
					
				when 5 =>
					input_data 	<= (others=>'0');
					input_data(CONFIG_DATA_BIT_IDX downto 0)  						<= std_logic_vector(to_unsigned(rcu_limits(5), CONFIG_DATA_BIT_IDX+1));
					input_data(CONFIG_UNIT_BIT_IDX downto CONFIG_DATA_BIT_IDX+1) 	<= "10";
					input_data(CONFIG_PARAM_BIT_IDX downto CONFIG_UNIT_BIT_IDX+1) 	<= "101";
					wait for period;
					
					for ocu_idx in 0 to (MAX_NUM_ECU_OPERANDS_PER_RCU+MAX_NUM_ECU_RESULTS_PER_RCU-1) loop
						input_data 	<= (others=>'0');
						input_data(CONFIG_DATA_BIT_IDX downto 0)  						<= std_logic_vector(to_unsigned(objects_RCU_5(ocu_idx), CONFIG_DATA_BIT_IDX+1));
						input_data(CONFIG_UNIT_BIT_IDX downto CONFIG_DATA_BIT_IDX+1) 	<= "10";
						input_data(CONFIG_PARAM_BIT_IDX downto CONFIG_UNIT_BIT_IDX+1) 	<= "000";
						wait for period;
						
						input_data 	<= (others=>'0');
						input_data(CONFIG_DATA_BIT_IDX downto 0)  						<= std_logic_vector(to_unsigned(reference_RCU_5(ocu_idx), CONFIG_DATA_BIT_IDX+1));
						input_data(CONFIG_UNIT_BIT_IDX downto CONFIG_DATA_BIT_IDX+1) 	<= "10";
						input_data(CONFIG_PARAM_BIT_IDX downto CONFIG_UNIT_BIT_IDX+1) 	<= "100";
						wait for period;
						
						input_data 	<= (others=>'0');
						input_data(CONFIG_DATA_BIT_IDX downto 0)  						<= std_logic_vector(to_unsigned(probability_RCU_5(ocu_idx), CONFIG_DATA_BIT_IDX+1));
						input_data(CONFIG_UNIT_BIT_IDX downto CONFIG_DATA_BIT_IDX+1) 	<= "10";
						input_data(CONFIG_PARAM_BIT_IDX downto CONFIG_UNIT_BIT_IDX+1) 	<= "011";
						wait for period;
					end loop;
			
				when others =>
					input_data 	<= (others=>'0');
					input_data(CONFIG_DATA_BIT_IDX downto 0)  						<= std_logic_vector(to_unsigned(rcu_limits(2), CONFIG_DATA_BIT_IDX+1));
					input_data(CONFIG_UNIT_BIT_IDX downto CONFIG_DATA_BIT_IDX+1) 	<= "10";
					input_data(CONFIG_PARAM_BIT_IDX downto CONFIG_UNIT_BIT_IDX+1) 	<= "101";
					wait for period;
					
					for ocu_idx in 0 to (MAX_NUM_ECU_OPERANDS_PER_RCU+MAX_NUM_ECU_RESULTS_PER_RCU-1) loop
						input_data 	<= (others=>'0');
						input_data(CONFIG_DATA_BIT_IDX downto 0)  						<= std_logic_vector(to_unsigned(objects_RCU_NL(ocu_idx), CONFIG_DATA_BIT_IDX+1));
						input_data(CONFIG_UNIT_BIT_IDX downto CONFIG_DATA_BIT_IDX+1) 	<= "10";
						input_data(CONFIG_PARAM_BIT_IDX downto CONFIG_UNIT_BIT_IDX+1) 	<= "000";
						wait for period;
						
						input_data 	<= (others=>'0');
						input_data(CONFIG_DATA_BIT_IDX downto 0)  						<= std_logic_vector(to_unsigned(reference_RCU_NL(ocu_idx), CONFIG_DATA_BIT_IDX+1));
						input_data(CONFIG_UNIT_BIT_IDX downto CONFIG_DATA_BIT_IDX+1) 	<= "10";
						input_data(CONFIG_PARAM_BIT_IDX downto CONFIG_UNIT_BIT_IDX+1) 	<= "100";
						wait for period;
						
						input_data 	<= (others=>'0');
						input_data(CONFIG_DATA_BIT_IDX downto 0)  						<= std_logic_vector(to_unsigned(probability_RCU_NL(ocu_idx), CONFIG_DATA_BIT_IDX+1));
						input_data(CONFIG_UNIT_BIT_IDX downto CONFIG_DATA_BIT_IDX+1) 	<= "10";
						input_data(CONFIG_PARAM_BIT_IDX downto CONFIG_UNIT_BIT_IDX+1) 	<= "011";
						wait for period;
					end loop;
					
			end case;
		end loop;
		cmd 		<= NOP;
		wait for 2*period;
		
		cmd <= START;
		wait for period;
		cmd <= NOP;
		
		wait until req_comp_step = '1';
		
		wait until req_finish = '1';
		
		wait;		
	end process;
end architecture RTL;
