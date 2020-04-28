library ieee;
use ieee.std_logic_1164.all;
use IEEE.math_real.all;
use work.mp_ocu_pkg.all;
use work.mp_global_pkg.all;


package mp_rcu_pkg is

	constant EXECUTION_LIMIT			: integer := 15;
	constant EXECUTION_LIMIT_BITS_WIDTH	: integer := integer(ceil(log2(real(EXECUTION_LIMIT))));
	
	type cmd_array 			is array(0 to MAX_NUM_ECU_OPERANDS_PER_RCU+MAX_NUM_ECU_RESULTS_PER_RCU-1) of ecu_command;
	type logic_array		is array(0 to MAX_NUM_ECU_OPERANDS_PER_RCU+MAX_NUM_ECU_RESULTS_PER_RCU-1) of std_logic;
	type to_rcu_if_array	is array(0 to MAX_NUM_ECU_OPERANDS_PER_RCU+MAX_NUM_ECU_RESULTS_PER_RCU-1) of to_rcu_if;
	
	type from_ocb_if is record
		object       	: std_logic_vector(NUM_OBJECT_TYPES_BIT_WIDTH-1 downto 0);
        num_active_objs	: std_logic_vector(MAX_NUM_OBJECTS_PER_TYPE_BITS_WIDTH-1 downto 0);
        probability		: std_logic_vector(PROBABILITY_BITS_WIDTH-1 downto 0);
	end record from_ocb_if;
	
	type to_ocb_if is record
		obj_queue		: std_logic;
        num_queued_objs	: std_logic_vector (MAX_NUM_OBJECTS_PER_TYPE_BITS_WIDTH-1 downto 0);
        obj_active		: std_logic;
        num_active_objs	: std_logic_vector(MAX_NUM_OBJECTS_PER_TYPE_BITS_WIDTH-1 downto 0);
	end record to_ocb_if;
	
	type rcu_command is (NOP, CONFIGURE, EXECUTE, CONFIG_LIMIT);
	
end package mp_rcu_pkg;


package body mp_rcu_pkg is
	
end package body mp_rcu_pkg;
