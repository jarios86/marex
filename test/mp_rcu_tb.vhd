library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.mp_global_pkg.all;
use work.mp_rcu_pkg.all;

entity mp_rcu_tb is
end entity mp_rcu_tb;

architecture RTL of mp_rcu_tb is
	
	type object_type is (NL, ALFA, OMEGA, DELTA, A, B, C, D); -- El número de object_types debe coincidir con la constante MAX_NUM_OBJECTS_TYPES
	
	constant period 		: time := 20 ns;
	signal clk 				: std_logic;
	signal rst_n 			: std_logic;
	signal elt_type 		: std_logic_vector(ELEMENT_TYPE_BITS_WIDTH-1 downto 0);
	signal num_in_elts 		: std_logic_vector (NUM_ELEMENTS_PER_TYPE_BITS_WIDTH-1 downto 0);
	signal cmd 				: rcu_command;
	signal ecu_config_idx 	: std_logic_vector(NUM_ECUs_PER_RCU_BITS_WITDH-1 downto 0);
	signal busy				: std_logic;
	signal elt_queue 		: std_logic;
	signal num_queued_elts 	: std_logic_vector (NUM_ELEMENTS_PER_TYPE_BITS_WIDTH-1 downto 0);
	signal elt_actual		 : std_logic;
	signal num_actual_elts 	: std_logic_vector (NUM_ELEMENTS_PER_TYPE_BITS_WIDTH-1 downto 0);
	
begin
	
	inst : entity work.mp_rcu
		port map(
			clk            	=> clk,
			rst_n          	=> rst_n,
			elt_type       	=> elt_type,
			num_in_elts    	=> num_in_elts,
			cmd            	=> cmd,
			ecu_config_idx 	=> ecu_config_idx,
			elt_queue		=> elt_queue,
			num_queued_elts	=> num_queued_elts,
			elt_actual		=> elt_actual,
			num_actual_elts	=> num_actual_elts,
			busy			=> busy
		);
		
	clock_driver : process
	begin
		clk <= '0';
		wait for period / 2;
		clk <= '1';
		wait for period / 2;
	end process clock_driver;
	
	
	stim_proc : process
	begin
		-- hold reset state.
		wait for period;
		rst_n <= '0';
		wait for period;
		rst_n <= '1';
		wait for period/2;
		
		-- insert stimulus here 
		
		cmd					<= CONFIGURE;
		elt_type			<= std_logic_vector(to_unsigned(object_type'pos(A),elt_type'length));
		num_in_elts			<= std_logic_vector(to_unsigned(5 ,num_in_elts'length));
		ecu_config_idx		<= std_logic_vector(to_unsigned(0 ,ecu_config_idx'length));
		wait for period;
		
		cmd					<= CONFIGURE;
		elt_type			<= std_logic_vector(to_unsigned(object_type'pos(B),elt_type'length));
		num_in_elts			<= std_logic_vector(to_unsigned(1 ,num_in_elts'length));
		ecu_config_idx		<= std_logic_vector(to_unsigned(1 ,ecu_config_idx'length));
		wait for period;
		
		cmd					<= CONFIGURE;
		elt_type			<= std_logic_vector(to_unsigned(object_type'pos(C),elt_type'length));
		num_in_elts			<= std_logic_vector(to_unsigned(3 ,num_in_elts'length));
		ecu_config_idx		<= std_logic_vector(to_unsigned(3 ,ecu_config_idx'length));
		wait for period;
		
		cmd					<= CONFIGURE;
		elt_type			<= std_logic_vector(to_unsigned(object_type'pos(NL),elt_type'length));
		num_in_elts			<= std_logic_vector(to_unsigned(0 ,num_in_elts'length));
		ecu_config_idx		<= std_logic_vector(to_unsigned(2 ,ecu_config_idx'length));
		wait for period;
		
		cmd					<= CONFIGURE;
		elt_type			<= std_logic_vector(to_unsigned(object_type'pos(NL),elt_type'length));
		num_in_elts			<= std_logic_vector(to_unsigned(0 ,num_in_elts'length));
		ecu_config_idx		<= std_logic_vector(to_unsigned(4 ,ecu_config_idx'length));
		wait for period;
		
		cmd					<= NOP;
		wait for 4*period;
		
		cmd					<= EXECUTE;
		elt_type			<= std_logic_vector(to_unsigned(object_type'pos(C),elt_type'length));
		num_in_elts			<= std_logic_vector(to_unsigned(3 ,num_in_elts'length));
		wait for period;
		cmd					<= NOP;
		
		wait until busy = '0';
		
		cmd					<= EXECUTE;
		elt_type			<= std_logic_vector(to_unsigned(object_type'pos(A),elt_type'length));
		num_in_elts			<= std_logic_vector(to_unsigned(3 ,num_in_elts'length));
		wait for period;
		cmd					<= NOP;
		
		wait until busy = '0';
		
		cmd					<= EXECUTE;
		elt_type			<= std_logic_vector(to_unsigned(object_type'pos(B),elt_type'length));
		num_in_elts			<= std_logic_vector(to_unsigned(3 ,num_in_elts'length));
		wait for period;
		cmd					<= NOP;
		
		wait until busy = '0';
		
		cmd					<= EXECUTE;
		elt_type			<= std_logic_vector(to_unsigned(object_type'pos(A),elt_type'length));
		num_in_elts			<= std_logic_vector(to_unsigned(6 ,num_in_elts'length));
		wait for period;
		cmd					<= NOP;
		
		wait until busy = '0';
		
		cmd					<= EXECUTE;
		elt_type			<= std_logic_vector(to_unsigned(object_type'pos(OMEGA),elt_type'length));
		num_in_elts			<= std_logic_vector(to_unsigned(3 ,num_in_elts'length));
		wait for period;
		cmd					<= NOP;
		
		wait on busy until busy = '0' for period;
		
		cmd					<= EXECUTE;
		elt_type			<= std_logic_vector(to_unsigned(object_type'pos(A),elt_type'length));
		num_in_elts			<= std_logic_vector(to_unsigned(1 ,num_in_elts'length));
		wait for period;
		cmd					<= NOP;
		
		wait until busy = '0';
		
--		cmd					<= EXECUTE;
--		elt_type			<= std_logic_vector(to_unsigned(object_type'pos(B),elt_type'length));
--		num_in_elts			<= std_logic_vector(to_unsigned(1 ,num_in_elts'length));
--		wait for period;
--		cmd					<= NOP;
--		
--		wait until busy = '0';
		
		cmd					<= EXECUTE;
		elt_type			<= std_logic_vector(to_unsigned(object_type'pos(C),elt_type'length));
		num_in_elts			<= std_logic_vector(to_unsigned(1 ,num_in_elts'length));
		wait for period;
		cmd					<= NOP;
		
		wait until busy = '0';
		
		cmd					<= CLEAR;
		wait for period;
		cmd					<= NOP;
		
		wait on busy until busy = '0' for period;
		
		cmd					<= EXECUTE;
		elt_type			<= std_logic_vector(to_unsigned(object_type'pos(A),elt_type'length));
		num_in_elts			<= std_logic_vector(to_unsigned(3 ,num_in_elts'length));
		wait for period;
		cmd					<= NOP;
		
		wait until busy = '0';
		
		cmd					<= EXECUTE;
		elt_type			<= std_logic_vector(to_unsigned(object_type'pos(B),elt_type'length));
		num_in_elts			<= std_logic_vector(to_unsigned(3 ,num_in_elts'length));
		wait for period;
		cmd					<= NOP;
		
		wait until busy = '0';
		
		cmd					<= EXECUTE;
		elt_type			<= std_logic_vector(to_unsigned(object_type'pos(A),elt_type'length));
		num_in_elts			<= std_logic_vector(to_unsigned(6 ,num_in_elts'length));
		wait for period;
		cmd					<= NOP;
		
		wait until busy = '0';
		
		cmd					<= EXECUTE;
		elt_type			<= std_logic_vector(to_unsigned(object_type'pos(OMEGA),elt_type'length));
		num_in_elts			<= std_logic_vector(to_unsigned(3 ,num_in_elts'length));
		wait for period;
		cmd					<= NOP;
		
		wait on busy until busy = '0' for period;
		
		cmd					<= EXECUTE;
		elt_type			<= std_logic_vector(to_unsigned(object_type'pos(A),elt_type'length));
		num_in_elts			<= std_logic_vector(to_unsigned(1 ,num_in_elts'length));
		wait for period;
		cmd					<= NOP;
		
		wait until busy = '0';
		
		cmd					<= EXECUTE;
		elt_type			<= std_logic_vector(to_unsigned(object_type'pos(B),elt_type'length));
		num_in_elts			<= std_logic_vector(to_unsigned(1 ,num_in_elts'length));
		wait for period;
		cmd					<= NOP;
		
		wait until busy = '0';
		
		cmd					<= EXECUTE;
		elt_type			<= std_logic_vector(to_unsigned(object_type'pos(C),elt_type'length));
		num_in_elts			<= std_logic_vector(to_unsigned(1 ,num_in_elts'length));
		wait for period;
		cmd					<= NOP;
		
		wait until busy = '0';
		
		cmd					<= CLEAR;
		wait for period;
		cmd					<= NOP;
		
		wait;
	end process;

end architecture RTL;
