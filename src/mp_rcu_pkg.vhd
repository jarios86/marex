library ieee;
use ieee.std_logic_1164.all;

use work.mp_ecu_pkg.all;
use work.mp_global_pkg.all;


package mp_rcu_pkg is

	type cmd_array 			is array(0 to MAX_NUM_ECU_OPERANDS_PER_RCU+MAX_NUM_ECU_RESULTS_PER_RCU-1) of ecu_command;
	type logic_array		is array(0 to MAX_NUM_ECU_OPERANDS_PER_RCU+MAX_NUM_ECU_RESULTS_PER_RCU-1) of std_logic;
	type logic_vector_array	is array(0 to MAX_NUM_ECU_OPERANDS_PER_RCU+MAX_NUM_ECU_RESULTS_PER_RCU-1) of std_logic_vector(NUM_ELEMENTS_PER_TYPE_BITS_WIDTH-1 downto 0);
	
	type rcu_command is (NOP, CONFIGURE, EXECUTE, CLEAR);
	
end package mp_rcu_pkg;


package body mp_rcu_pkg is
	
end package body mp_rcu_pkg;
