library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.math_real.all;

package mp_global_pkg is

	constant MAX_NUM_ELEMENT_TYPES    			: integer := 8;
  	constant ELEMENT_TYPE_BITS_WIDTH			: integer := integer(ceil(log2(real(MAX_NUM_ELEMENT_TYPES))));
  	
  	constant MAX_NUM_ELEMENTS_PER_TYPE 			: integer := 16;
  	constant NUM_ELEMENTS_PER_TYPE_BITS_WIDTH   : integer := integer(ceil(log2(real(MAX_NUM_ELEMENTS_PER_TYPE))));
  	
  	constant MAX_NUM_ECU_OPERANDS_PER_RCU		: integer := 3;
	constant MAX_NUM_ECU_RESULTS_PER_RCU		: integer := 2;
	constant NUM_ECUs_PER_RCU_BITS_WITDH		: integer := integer(ceil(log2(real(MAX_NUM_ECU_OPERANDS_PER_RCU+MAX_NUM_ECU_RESULTS_PER_RCU))));
  	
  	type special_object_types is (NL, ALFA, OMEGA, DELTA);
  	
end package mp_global_pkg;


package body mp_global_pkg is
	
end package body mp_global_pkg;
