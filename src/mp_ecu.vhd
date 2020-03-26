library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.numeric_std_unsigned.all;
use ieee.math_real.all;

use work.mp_global_pkg.all;
use work.mp_ecu_pkg.all;

entity mp_ecu is --Element Container Unit
	port(
		clk				: in std_logic;
		rst_n			: in std_logic;
		elt_type       	: in std_logic_vector (ELEMENT_TYPE_BITS_WIDTH-1 downto 0);
        num_in_elts    	: in std_logic_vector (NUM_ELEMENTS_PER_TYPE_BITS_WIDTH-1 downto 0);
        cmd            	: in ecu_command;
        ready          	: out std_logic;
        elt_queue		: out std_logic;
        elt_actual		: out std_logic;
        --busy			: out std_logic;
        num_out_elts   	: out std_logic_vector (NUM_ELEMENTS_PER_TYPE_BITS_WIDTH-1 downto 0)
	);
end entity mp_ecu;

architecture RTL of mp_ecu is
	
	--type state is (idle, c_and_c, drain, config, compute, sprout, purge);
	--signal r_mp_ecu_control_state, n_mp_ecu_control_state : state;
	
	signal r_elt_type, n_elt_type					: std_logic_vector(ELEMENT_TYPE_BITS_WIDTH-1 downto 0);
	signal r_num_ref_elts, n_num_ref_elts			: std_logic_vector(NUM_ELEMENTS_PER_TYPE_BITS_WIDTH-1 downto 0);
	signal r_num_actual_elts, n_num_actual_elts		: std_logic_vector(NUM_ELEMENTS_PER_TYPE_BITS_WIDTH-1 downto 0);
	signal r_num_queued_elts, n_num_queued_elts		: std_logic_vector(NUM_ELEMENTS_PER_TYPE_BITS_WIDTH-1 downto 0);
	
	signal r_num_out_elts, n_num_out_elts	: std_logic_vector (NUM_ELEMENTS_PER_TYPE_BITS_WIDTH-1 downto 0);
	signal r_elt_queue, n_elt_queue			: std_logic;
	signal r_ready, n_ready					: std_logic;
	signal r_elt_actual, n_elt_actual		: std_logic;
	--signal r_busy, n_busy					: std_logic;
	
begin
	
	process (clk, rst_n)
	begin
		if(rst_n = '0') then
			--r_mp_ecu_control_state <= idle;
			
			r_num_actual_elts	<= (others=>'0');
			r_num_queued_elts	<= (others=>'0');
			r_num_out_elts		<= (others=>'0');
			r_elt_queue			<= '0';
			r_ready				<= '0';
			r_elt_type			<= (others=>'0');
			r_num_ref_elts		<= (others=>'0');
			r_elt_actual		<= '0';
			--r_busy				<= '0';
			
		elsif rising_edge(clk) then
			--r_mp_ecu_control_state 	<= n_mp_ecu_control_state;
			
			r_num_actual_elts		<= n_num_actual_elts;
			r_num_queued_elts		<= n_num_queued_elts;
			r_num_out_elts			<= n_num_out_elts;
			r_elt_queue				<= n_elt_queue;
			r_ready					<= n_ready;
			r_elt_type				<= n_elt_type;
			r_num_ref_elts			<= n_num_ref_elts;
			r_elt_actual			<= n_elt_actual;
			--r_busy					<= n_busy;
		end if;
	end process;
	
	
	process (ALL)
	begin
		--n_mp_ecu_control_state 	<= r_mp_ecu_control_state;
		n_num_actual_elts		<= r_num_actual_elts;
		n_num_queued_elts		<= r_num_queued_elts;
		n_num_out_elts			<= r_num_out_elts;
		n_elt_queue				<= '0';
		n_ready					<= r_ready;
		n_elt_actual			<= '0';
		n_elt_type				<= r_elt_type;
		n_num_ref_elts			<= r_num_ref_elts;
		--n_busy					<= '0';
		
		case (cmd) is
			when CONFIGURE =>
				n_elt_type			<= elt_type;
				n_num_ref_elts		<= num_in_elts;
				n_num_actual_elts	<= (others=>'0');
				n_num_queued_elts	<= (others=>'0');
				if(elt_type = std_logic_vector(to_unsigned(special_object_types'pos(NL),elt_type'length))) then
					n_ready <= '1';
				end if;
			
			when CATCH =>
				if(elt_type = r_elt_type) then
					n_elt_actual <= '1';
					if((('0' & r_num_actual_elts) + ('0' & num_in_elts)) > (MAX_NUM_ELEMENTS_PER_TYPE-1)) then
						n_num_actual_elts 	<= std_logic_vector(to_unsigned(MAX_NUM_ELEMENTS_PER_TYPE-1,n_num_actual_elts'length));
						n_num_out_elts 		<= (MAX_NUM_ELEMENTS_PER_TYPE-1) - r_num_actual_elts;
					else
						n_num_actual_elts 	<= r_num_actual_elts + num_in_elts;
						n_num_out_elts 		<= num_in_elts;
					end if;
				end if;
				if(n_num_actual_elts >= r_num_ref_elts) then
					n_ready <= '1';
				else
					n_ready <= '0';
				end if;
				
			when EXECUTE_OPERAND =>
				if(r_ready = '1') then
					n_num_actual_elts	<= r_num_actual_elts - r_num_ref_elts;
					--n_busy				<= '1';
				end if;
				if(n_num_actual_elts >= r_num_ref_elts) then
					n_ready <= '1';
				else
					n_ready <= '0';
				end if;
				
			when EXECUTE_RESULT =>
				if((('0' & r_num_actual_elts) + ('0' & r_num_ref_elts)) > (MAX_NUM_ELEMENTS_PER_TYPE-1)) then
					n_num_queued_elts 	<= std_logic_vector(to_unsigned(MAX_NUM_ELEMENTS_PER_TYPE-1,n_num_queued_elts'length));
				else
					n_num_queued_elts 	<= r_num_queued_elts + r_num_ref_elts;
				end if;
				--n_busy 					<= '1';
				
			when DRAIN =>
				if(elt_type = r_elt_type) then
					n_elt_queue 		<= '1';
					n_num_out_elts		<= r_num_queued_elts;
					n_num_queued_elts	<= (others=>'0');
				end if;
			
			when PURGE =>
				if(elt_type = r_elt_type) then
					n_elt_queue 		<= '1';
					n_elt_actual		<= '1';
					n_num_out_elts		<= r_num_queued_elts + r_num_actual_elts;
					n_num_queued_elts	<= (others=>'0');
					n_num_actual_elts	<= (others=>'0');
					if(n_num_actual_elts >= r_num_ref_elts) then
						n_ready <= '1';
					else
						n_ready <= '0';
					end if;
				end if;
				
			when CLEAR =>
				n_num_queued_elts	<= (others=>'0');
				n_num_actual_elts	<= (others=>'0');
				if(n_num_actual_elts >= r_num_ref_elts) then
					n_ready <= '1';
				else
					n_ready <= '0';
				end if;
				
			when NOP =>
				null;
				
		end case;
	end process;
	
	
	process (ALL)
	begin
		ready			<= r_ready;
		elt_queue		<= r_elt_queue;
		num_out_elts 	<= r_num_out_elts;
		elt_actual		<= r_elt_actual;
		--busy			<= r_busy;
	end process;
		
end architecture RTL;
