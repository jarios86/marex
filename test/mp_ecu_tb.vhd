library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.mp_global_pkg.all;
use work.mp_ecu_pkg.all;

entity mp_ecu_tb is
end entity mp_ecu_tb;

architecture RTL of mp_ecu_tb is
	
	type object_type is (NL, ALFA, OMEGA, DELTA, A, B, C, D); -- El número de object_types debe coincidir con la constante MAX_NUM_OBJECTS_TYPES
	
	signal clk 					: std_logic;
	constant period 			: time := 20 ns;
	signal rst_n 				: std_logic := '1';
	signal element 				: std_logic_vector (ELEMENT_TYPE_BITS_WIDTH-1 downto 0);
	signal num_in_elts		 	: std_logic_vector (NUM_ELEMENTS_PER_TYPE_BITS_WIDTH-1 downto 0);
	signal cmd 					: ecu_command;
	signal ready 				: std_logic;
	signal elt_deliver	 		: std_logic;
	signal num_out_elts		 	: std_logic_vector (NUM_ELEMENTS_PER_TYPE_BITS_WIDTH-1 downto 0);
	signal elt_hold 			: std_logic;
	--signal busy 				: std_logic;
	
begin
	
	inst : entity work.mp_ecu
		port map(
			clk          => clk,
			rst_n        => rst_n,
			elt_type     => element,
			num_in_elts  => num_in_elts,
			cmd          => cmd,
			ready        => ready,
			elt_queue    => elt_deliver,
			elt_actual	 => elt_hold,
			--busy		 => busy,
			num_out_elts => num_out_elts
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
		element				<= std_logic_vector(to_unsigned(object_type'pos(A),element'length));
		num_in_elts	<= std_logic_vector(to_unsigned(4 ,num_in_elts'length));
		wait for period;
		
		cmd					<= NOP;
		wait for 4*period;
		
		cmd					<= CATCH;
		element				<= std_logic_vector(to_unsigned(object_type'pos(A),element'length));
		num_in_elts	<= std_logic_vector(to_unsigned(2 ,num_in_elts'length));
		wait for period;
		
		cmd					<= CATCH;
		element				<= std_logic_vector(to_unsigned(object_type'pos(A),element'length));
		num_in_elts	<= std_logic_vector(to_unsigned(15 ,num_in_elts'length));
		wait for period;
		
		cmd					<= NOP;
		wait for 4*period;
		
		cmd					<= DRAIN;
		element				<= std_logic_vector(to_unsigned(object_type'pos(A),element'length));
		wait for period;
		
		cmd					<= NOP;
		wait for 4*period;
		
		cmd					<= CATCH;
		element				<= std_logic_vector(to_unsigned(object_type'pos(A),element'length));
		num_in_elts	<= std_logic_vector(to_unsigned(5 ,num_in_elts'length));
		wait for period;
		
		cmd					<= NOP;
		wait for 4*period;
		
		cmd					<= EXECUTE_OPERAND;
		wait for period;
		
		cmd					<= NOP;
		wait for 4*period;
		
		cmd					<= CATCH;
		element				<= std_logic_vector(to_unsigned(object_type'pos(A),element'length));
		num_in_elts	<= std_logic_vector(to_unsigned(5 ,num_in_elts'length));
		wait for period;
		
		cmd					<= NOP;
		wait for 4*period;
		
		cmd					<= DRAIN;
		element				<= std_logic_vector(to_unsigned(object_type'pos(B),element'length));
		wait for period;
		
		cmd					<= NOP;
		wait for 4*period;
		
		cmd					<= PURGE;
		element				<= std_logic_vector(to_unsigned(object_type'pos(A),element'length));
		wait for period;
		
		cmd					<= NOP;
		wait for 4*period;
		
		cmd					<= CONFIGURE;
		element				<= std_logic_vector(to_unsigned(object_type'pos(C),element'length));
		num_in_elts	<= std_logic_vector(to_unsigned(4 ,num_in_elts'length));
		wait for period;
		
		cmd					<= NOP;
		wait for 4*period;
		
		cmd					<= EXECUTE_RESULT;
		wait for period;
		
		cmd					<= NOP;
		wait for 4*period;
		
		cmd					<= DRAIN;
		element				<= std_logic_vector(to_unsigned(object_type'pos(C),element'length));
		wait for period;
		
		cmd					<= NOP;
      	wait;
	end process;
	
end architecture RTL;
