library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.mp_global_pkg.all;
use work.mp_ocu_pkg.all;

entity mp_ocu_tb is
end entity mp_ocu_tb;

architecture RTL of mp_ocu_tb is
	
	type object_type is (NL, ALFA, OMEGA, DELTA, A, B, C, D); -- El número de object_types debe coincidir con la constante MAX_NUM_OBJECTS_TYPES
	
	signal clk 					: std_logic;
	constant period 			: time := 20 ns;
	signal rst_n 				: std_logic := '1';
	signal from_rcu				: from_rcu_if;
	signal to_rcu				: to_rcu_if; -- @suppress "signal to_rcu is never read"
	signal cmd 					: ecu_command;
	signal ready 				: std_logic; -- @suppress "signal ready is never read"
	
begin
	
	inst : entity work.mp_ocu
		port map(
			clk        => clk,
			rst_n      => rst_n,
			rcu_in_if  => from_rcu,
			cmd        => cmd,
			ready      => ready,
			rcu_out_if => to_rcu
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
		wait for period/2;
		rst_n <= '0';
		wait for period;
		rst_n <= '1';
		wait for period;
		
		-- insert stimulus here 
		
		cmd						<= CONFIGURE;
		from_rcu.object			<= std_logic_vector(to_unsigned(object_type'pos(A),from_rcu.object'length));
		from_rcu.num_in_objs	<= std_logic_vector(to_unsigned(4 ,from_rcu.num_in_objs'length));
		from_rcu.probability	<= std_logic_vector(to_unsigned(25 ,from_rcu.probability'length));
		wait for period;
		
		cmd						<= NOP;
		wait for 4*period;
		
		cmd						<= CATCH;
		from_rcu.object			<= std_logic_vector(to_unsigned(object_type'pos(A),from_rcu.object'length));
		from_rcu.num_in_objs	<= std_logic_vector(to_unsigned(2 ,from_rcu.num_in_objs'length));
		from_rcu.probability	<= std_logic_vector(to_unsigned(26 ,from_rcu.probability'length));
		wait for period;
		
		cmd						<= CATCH;
		from_rcu.object			<= std_logic_vector(to_unsigned(object_type'pos(A),from_rcu.object'length));
		from_rcu.num_in_objs	<= std_logic_vector(to_unsigned(15 ,from_rcu.num_in_objs'length));
		wait for period;
		
		cmd						<= NOP;
		wait for 4*period;
		
		cmd						<= DRAIN;
		from_rcu.object			<= std_logic_vector(to_unsigned(object_type'pos(A),from_rcu.object'length));
		wait for period;
		
		cmd						<= NOP;
		wait for 4*period;
		
		cmd						<= CATCH;
		from_rcu.object			<= std_logic_vector(to_unsigned(object_type'pos(A),from_rcu.object'length));
		from_rcu.num_in_objs	<= std_logic_vector(to_unsigned(5 ,from_rcu.num_in_objs'length));
		from_rcu.probability	<= std_logic_vector(to_unsigned(20 ,from_rcu.probability'length));
		wait for period;
		
		cmd						<= NOP;
		wait for 4*period;
		
		cmd						<= EXECUTE_OPERAND;
		wait for period;
		
		cmd						<= NOP;
		wait for 4*period;
		
		cmd						<= CATCH;
		from_rcu.object			<= std_logic_vector(to_unsigned(object_type'pos(A),from_rcu.object'length));
		from_rcu.num_in_objs	<= std_logic_vector(to_unsigned(5 ,from_rcu.num_in_objs'length));
		from_rcu.probability	<= std_logic_vector(to_unsigned(25 ,from_rcu.probability'length));
		wait for period;
		
		cmd						<= NOP;
		wait for 4*period;
		
		cmd						<= DRAIN;
		from_rcu.object			<= std_logic_vector(to_unsigned(object_type'pos(B),from_rcu.object'length));
		wait for period;
		
		cmd						<= NOP;
		wait for 4*period;
		
		cmd						<= PURGE;
		from_rcu.object			<= std_logic_vector(to_unsigned(object_type'pos(A),from_rcu.object'length));
		wait for period;
		
		cmd						<= NOP;
		wait for 4*period;
		
		cmd						<= CONFIGURE;
		from_rcu.object			<= std_logic_vector(to_unsigned(object_type'pos(C),from_rcu.object'length));
		from_rcu.num_in_objs	<= std_logic_vector(to_unsigned(4 ,from_rcu.num_in_objs'length));
		from_rcu.probability	<= std_logic_vector(to_unsigned(100 ,from_rcu.probability'length));
		wait for period;
		
		cmd						<= NOP;
		wait for 4*period;
		
		cmd						<= EXECUTE_RESULT;
		wait for period;
		
		cmd						<= NOP;
		wait for 4*period;
		
		cmd						<= DRAIN;
		from_rcu.object			<= std_logic_vector(to_unsigned(object_type'pos(C),from_rcu.object'length));
		wait for period;
		
		cmd						<= NOP;
      	wait;
	end process;
	
end architecture RTL;
