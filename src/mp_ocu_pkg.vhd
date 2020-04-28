library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.math_real.all;
use work.mp_global_pkg.all;

package mp_ocu_pkg is

  	type ecu_command is (NOP, CONFIGURE, CATCH, DRAIN, EXECUTE_OPERAND, EXECUTE_RESULT, PURGE, CLEAR);
  	
  	type from_rcu_if is record
  		object       	: std_logic_vector(NUM_OBJECT_TYPES_BIT_WIDTH-1 downto 0);
        num_in_objs    	: std_logic_vector(MAX_NUM_OBJECTS_PER_TYPE_BITS_WIDTH-1 downto 0);
        probability		: std_logic_vector(PROBABILITY_BITS_WIDTH-1 downto 0); 
  	end record from_rcu_if;
  	
  	type to_rcu_if is record
  		obj_queue		: std_logic;
        obj_active		: std_logic;
        num_out_objs   	: std_logic_vector (MAX_NUM_OBJECTS_PER_TYPE_BITS_WIDTH-1 downto 0);
  	end record to_rcu_if;
  	
  	type obj_parameters is record
		object 		: std_logic_vector(NUM_OBJECT_TYPES_BIT_WIDTH-1 downto 0);
  		probability	: std_logic_vector(PROBABILITY_BITS_WIDTH-1 downto 0);
  		active_objs	: std_logic_vector(MAX_NUM_OBJECTS_PER_TYPE_BITS_WIDTH-1 downto 0);
  		queued_objs	: std_logic_vector(MAX_NUM_OBJECTS_PER_TYPE_BITS_WIDTH-1 downto 0);
	end record obj_parameters;
  	
  	type ocu_members is record
  		obj_param	: obj_parameters;
  		reference	: std_logic_vector(MAX_NUM_OBJECTS_PER_TYPE_BITS_WIDTH-1 downto 0);
  	end record ocu_members;
  
end package mp_ocu_pkg;


package body mp_ocu_pkg is
	
end package body mp_ocu_pkg;
