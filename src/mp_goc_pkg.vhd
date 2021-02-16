library ieee;
use ieee.std_logic_1164.all;

use work.mp_global_pkg.all;

package mp_goc_pkg is
	
	type elt_logic_vector_array		is array (0 to NUM_OBJECT_TYPES-1) of std_logic_vector(NUM_OBJECT_TYPES_BIT_WIDTH-1 downto 0);
	type num_elt_logic_vector_array	is array (0 to NUM_OBJECT_TYPES-1) of std_logic_vector(MAX_NUM_OBJECTS_PER_TYPE_BIT_WIDTH-1 downto 0);
	type prob_logic_vector_array	is array (0 to NUM_OBJECT_TYPES-1) of std_logic_vector(PROBABILITY_BIT_WIDTH-1 downto 0);
	
end package mp_goc_pkg;

package body mp_goc_pkg is
	
end package body mp_goc_pkg;
