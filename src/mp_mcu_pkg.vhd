library ieee;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.math_real.all;
use work.mp_global_pkg.all;
use work.mp_rcu_pkg.all;
use work.mp_ocu_pkg.all;

package mp_mcu_pkg is

	type mcu_command 				is (NOP, CONFIG, START);
	type from_ocb_if_array			is array(0 to MAX_NUM_RULES-1) of from_ocb_if;
	type to_ocb_if_array			is array(0 to MAX_NUM_RULES-1) of to_ocb_if;
	type rcu_command_array			is array(0 to MAX_NUM_RULES-1) of rcu_command;
	type rcu_ecu_config_id_array	is array(0 to MAX_NUM_RULES-1) of std_logic_vector(NUM_ECUs_PER_RCU_BIT_WITDH-1 downto 0);
	type std_logic_array			is array(0 to MAX_NUM_RULES-1) of std_logic;
	
	type OCB is array(0 to MAX_NUM_RULES-1) of obj_parameters;
	
	constant RCU_EXECUTION_CICLES 				: integer := 4;
	constant RCU_EXECUTION_CICLES_BITS_WIDTH	: integer := integer(ceil(log2(real(RCU_EXECUTION_CICLES))));
	
	constant CONFIG_DATA_BIT_IDX		: integer := MAX_NUM_OBJECTS_PER_TYPE-1;
	constant CONFIG_UNIT_BIT_IDX		: integer := CONFIG_DATA_BIT_IDX+2;
	constant CONFIG_PARAM_BIT_IDX		: integer := CONFIG_UNIT_BIT_IDX+3;
	constant CONFIG_LAST_DATA_BIT_IDX	: integer := CONFIG_PARAM_BIT_IDX+1;
	
end package mp_mcu_pkg;

package body mp_mcu_pkg is
	
end package body mp_mcu_pkg;
