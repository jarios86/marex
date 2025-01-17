library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.math_real.all;

package mp_global_pkg is

  	type special_object_types is (NL, ALFA, OMEGA, DELTA);

	constant NUM_OBJECT_TYPES    					: integer := 12;
  	constant NUM_OBJECT_TYPES_BIT_WIDTH				: integer := integer(ceil(log2(real(NUM_OBJECT_TYPES))));
  	
  	constant MAX_NUM_OBJECTS_PER_TYPE 				: integer := 16;
  	constant MAX_NUM_OBJECTS_PER_TYPE_BIT_WIDTH   	: integer := integer(ceil(log2(real(MAX_NUM_OBJECTS_PER_TYPE))));
  	
  	constant MAX_NUM_ECU_OPERANDS_PER_RCU			: integer := 4;
	constant MAX_NUM_ECU_RESULTS_PER_RCU			: integer := 2;
	constant NUM_ECUs_PER_RCU_BIT_WITDH				: integer := integer(ceil(log2(real(MAX_NUM_ECU_OPERANDS_PER_RCU+MAX_NUM_ECU_RESULTS_PER_RCU))));
  	
  	constant PROBABILITY_BIT_WIDTH 					: integer := 8;
  	constant INITIAL_PROB_SEED						: integer := 32;
  	
  	constant MAX_NUM_RULES							: integer := 8;
  	constant MAX_NUM_RULES_BIT_WIDTH				: integer := integer(ceil(log2(real(MAX_NUM_RULES))));
  	
  	constant AXI_INTERFACE_BIT_WIDTH				: integer := 32;
  	
end package mp_global_pkg;


package body mp_global_pkg is
	
end package body mp_global_pkg;
