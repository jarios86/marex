library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.math_real.all;

package mp_ecu_pkg is

	--constant MAX_CMDS		: integer := 4;
  	--constant CMD_BITS_WIDTH	: integer := integer(ceil(log2(real(MAX_CMDS))));
  	
  	type ecu_command is (NOP, CONFIGURE, CATCH, DRAIN, EXECUTE_OPERAND, EXECUTE_RESULT, PURGE, CLEAR);
  
end package mp_ecu_pkg;


package body mp_ecu_pkg is
	
end package body mp_ecu_pkg;
