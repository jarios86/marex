library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.numeric_std_unsigned.all;

use work.mp_global_pkg.all;
use work.mp_rcu_pkg.all;

entity mp_rcu_tb is
end entity mp_rcu_tb;

architecture RTL of mp_rcu_tb is
	
	type object_type is (NL, ALFA, OMEGA, DELTA, A, B, C, D); -- El número de object_types debe coincidir con la constante MAX_NUM_OBJECTS_TYPES
	
	constant period 		: time := 20 ns;
	signal clk 				: std_logic;
	signal rst_n 			: std_logic;
	signal cmd 				: rcu_command;
	signal ecu_config_idx 	: std_logic_vector(NUM_ECUs_PER_RCU_BITS_WITDH-1 downto 0);
	signal busy				: std_logic;
	signal from_ocb 		: from_ocb_if;
	signal to_ocb	 		: to_ocb_if; -- @suppress "signal to_ocb is never read"
	
	type objetc_array 		is array (0 to NUM_OBJECT_TYPES-1) of object_type;
	signal objects_GOC		: objetc_array := (ALFA, A, B, C, D, DELTA, OMEGA, NL);
	
	type integer_array 		is array (0 to NUM_OBJECT_TYPES-1) of integer;
	signal probability_GOC	: integer_array := (0, 1, 1, 1, 1, 1, 0, 0);
	signal reference_GOC	: integer_array := (0, 2, 1, 3, 0, 1, 0, 0);
	signal active_GOC		: integer_array := (0, 7, 5, 0, 0, 0, 0, 0);
	signal queued_GOC		: integer_array := (0, 0, 0, 0, 0, 0, 0, 0);
	
	constant CMP_ITERATIONS : integer := 2;
	
begin
	
	inst : entity work.mp_rcu
		port map(
			clk            => clk,
			rst_n          => rst_n,
			ocb_in_if      => from_ocb,
			cmd            => cmd,
			ecu_config_idx => ecu_config_idx,
			ocb_out_if     => to_ocb,
			busy           => busy
		);
		
	clock_driver : process
	begin
		clk <= '0';
		wait for period / 2;
		clk <= '1';
		wait for period / 2;
	end process clock_driver;
	
	
	stim_proc : process
		variable cmp_step_init : boolean := false;
	begin
		-- hold reset state.
		wait for period;
		rst_n <= '0';
		wait for period;
		rst_n <= '1';
		wait for period/2;
		
		-- insert stimulus here 		
		cmd							<= CONFIG_LIMIT;
		from_ocb.num_active_objs	<= std_logic_vector(to_unsigned(4 ,from_ocb.num_active_objs'length));
		wait for period;
		
		cmd							<= CONFIGURE;
		from_ocb.object				<= std_logic_vector(to_unsigned(object_type'pos(objects_GOC(1)), from_ocb.object'length));
		from_ocb.num_active_objs	<= std_logic_vector(to_unsigned(reference_GOC(1) ,from_ocb.num_active_objs'length));
		from_ocb.probability		<= std_logic_vector(to_unsigned(20, from_ocb.probability'length));
		ecu_config_idx				<= std_logic_vector(to_unsigned(0, ecu_config_idx'length));
		wait for period;
		
		cmd							<= CONFIGURE;
		from_ocb.object				<= std_logic_vector(to_unsigned(object_type'pos(objects_GOC(2)), from_ocb.object'length));
		from_ocb.num_active_objs	<= std_logic_vector(to_unsigned(reference_GOC(2) ,from_ocb.num_active_objs'length));
		from_ocb.probability		<= std_logic_vector(to_unsigned(20, from_ocb.probability'length));
		ecu_config_idx				<= std_logic_vector(to_unsigned(1, ecu_config_idx'length));
		wait for period;
		
		cmd							<= CONFIGURE;
		from_ocb.object				<= std_logic_vector(to_unsigned(object_type'pos(objects_GOC(3)), from_ocb.object'length));
		from_ocb.num_active_objs	<= std_logic_vector(to_unsigned(reference_GOC(3) ,from_ocb.num_active_objs'length));
		from_ocb.probability		<= std_logic_vector(to_unsigned(20, from_ocb.probability'length));
		ecu_config_idx				<= std_logic_vector(to_unsigned(4, ecu_config_idx'length));
		wait for period;
		
		cmd							<= CONFIGURE;
		from_ocb.object				<= std_logic_vector(to_unsigned(object_type'pos(objects_GOC(7)), from_ocb.object'length));
		from_ocb.num_active_objs	<= std_logic_vector(to_unsigned(reference_GOC(7) ,from_ocb.num_active_objs'length));
		from_ocb.probability		<= std_logic_vector(to_unsigned(0, from_ocb.probability'length));
		ecu_config_idx				<= std_logic_vector(to_unsigned(2, ecu_config_idx'length));
		wait for period;
		
		cmd							<= CONFIGURE;
		from_ocb.object				<= std_logic_vector(to_unsigned(object_type'pos(objects_GOC(7)), from_ocb.object'length));
		from_ocb.num_active_objs	<= std_logic_vector(to_unsigned(reference_GOC(7) ,from_ocb.num_active_objs'length));
		from_ocb.probability		<= std_logic_vector(to_unsigned(0, from_ocb.probability'length));
		ecu_config_idx				<= std_logic_vector(to_unsigned(3, ecu_config_idx'length));
		wait for period;
		
		cmd							<= CONFIGURE;
		from_ocb.object				<= std_logic_vector(to_unsigned(object_type'pos(objects_GOC(7)), from_ocb.object'length));
		from_ocb.num_active_objs	<= std_logic_vector(to_unsigned(reference_GOC(7), from_ocb.num_active_objs'length));
		from_ocb.probability		<= std_logic_vector(to_unsigned(0, from_ocb.probability'length));
		ecu_config_idx				<= std_logic_vector(to_unsigned(5, ecu_config_idx'length));
		wait for period;
		
		cmd					<= NOP;
		wait for 4*period;
		
		cmp_step_init := true;
		for COMP_idx in 0 to (CMP_ITERATIONS-1) loop
			for GOC_idx in 0 to (NUM_OBJECT_TYPES-1) loop
				if(GOC_idx /= 0 or cmp_step_init) then
					cmd							<= EXECUTE;
					from_ocb.object				<= std_logic_vector(to_unsigned(object_type'pos(objects_GOC(GOC_idx)), from_ocb.object'length));
					from_ocb.num_active_objs	<= std_logic_vector(to_unsigned(active_GOC(GOC_idx), from_ocb.num_active_objs'length));
					from_ocb.probability		<= std_logic_vector(to_unsigned(probability_GOC(GOC_idx), from_ocb.probability'length));
					wait for period;
					cmd							<= NOP;
					wait for period;
					if(to_ocb.obj_active = '1') then -- Generación OMEGA
						active_GOC(GOC_idx) <= active_GOC(GOC_idx) + to_integer(unsigned(to_ocb.num_active_objs));
					end if;
					wait for period;
					if(to_ocb.obj_queue = '1') then
						queued_GOC(GOC_idx) <= queued_GOC(GOC_idx) + to_integer(unsigned(to_ocb.num_queued_objs));
					end if;
					if(to_ocb.obj_active = '1') then -- Purga
						active_GOC(GOC_idx) <= active_GOC(GOC_idx) + to_integer(unsigned(to_ocb.num_active_objs));
					end if;
					wait for period;
					if(to_ocb.obj_active = '1') then
						active_GOC(GOC_idx) <= active_GOC(GOC_idx) - to_integer(unsigned(to_ocb.num_active_objs));
					end if;			
				end if;
			end loop;
			cmp_step_init := false;
		end loop;
		
		cmp_step_init := true;
		for COMP_idx in 0 to (CMP_ITERATIONS-1) loop
			for GOC_idx in 0 to (NUM_OBJECT_TYPES-1) loop
				if(GOC_idx /= 0 or cmp_step_init) then
					cmd							<= EXECUTE;
					from_ocb.object				<= std_logic_vector(to_unsigned(object_type'pos(objects_GOC(GOC_idx)), from_ocb.object'length));
					from_ocb.num_active_objs	<= std_logic_vector(to_unsigned(active_GOC(GOC_idx), from_ocb.num_active_objs'length));
					from_ocb.probability		<= std_logic_vector(to_unsigned(probability_GOC(GOC_idx), from_ocb.probability'length));
					wait for period;
					cmd							<= NOP;
					wait for period;
					if(to_ocb.obj_active = '1') then -- Generación OMEGA
						active_GOC(GOC_idx) <= active_GOC(GOC_idx) + to_integer(unsigned(to_ocb.num_active_objs));
					end if;
					wait for period;
					if(to_ocb.obj_queue = '1') then
						queued_GOC(GOC_idx) <= queued_GOC(GOC_idx) + to_integer(unsigned(to_ocb.num_queued_objs));
					end if;
					if(to_ocb.obj_active = '1') then -- Purga
						active_GOC(GOC_idx) <= active_GOC(GOC_idx) + to_integer(unsigned(to_ocb.num_active_objs));
					end if;
					wait for period;
					if(to_ocb.obj_active = '1') then
						active_GOC(GOC_idx) <= active_GOC(GOC_idx) - to_integer(unsigned(to_ocb.num_active_objs));
					end if;			
				end if;
			end loop;
			cmp_step_init := false;
		end loop;
		
--		wait on busy until busy = '0' for period;
--		
--		cmd							<= EXECUTE;
--		from_ocb.object				<= std_logic_vector(to_unsigned(object_type'pos(ALFA),from_ocb.object'length));
--		from_ocb.num_active_objs	<= std_logic_vector(to_unsigned(0 ,from_ocb.num_active_objs'length));
--		from_ocb.probability		<= std_logic_vector(to_unsigned(0 ,from_ocb.probability'length));
--		wait for period;
--		
--		cmd							<= NOP;
--		
--		wait for period;
--		
--		cmd							<= EXECUTE;
--		from_ocb.object				<= std_logic_vector(to_unsigned(object_type'pos(A),from_ocb.object'length));
--		from_ocb.num_active_objs	<= std_logic_vector(to_unsigned(1 ,from_ocb.num_active_objs'length));
--		from_ocb.probability		<= std_logic_vector(to_unsigned(100 ,from_ocb.probability'length));
--		wait for period;
--		cmd							<= NOP;
--		
--		wait until busy = '0';
--		
--		cmd							<= EXECUTE;
--		from_ocb.object				<= std_logic_vector(to_unsigned(object_type'pos(B),from_ocb.object'length));
--		from_ocb.num_active_objs	<= std_logic_vector(to_unsigned(1 ,from_ocb.num_active_objs'length));
--		from_ocb.probability		<= std_logic_vector(to_unsigned(2 ,from_ocb.probability'length));
--		wait for period;
--		cmd							<= NOP;
--		
--		wait until busy = '0';
--		
--		cmd							<= EXECUTE;
--		from_ocb.object				<= std_logic_vector(to_unsigned(object_type'pos(C),from_ocb.object'length));
--		from_ocb.num_active_objs	<= std_logic_vector(to_unsigned(1 ,from_ocb.num_active_objs'length));
--		from_ocb.probability		<= std_logic_vector(to_unsigned(0 ,from_ocb.probability'length));
--		wait for period;
--		cmd							<= NOP;
--		
--		wait until busy = '0';
--		
--		cmd							<= EXECUTE;
--		from_ocb.object				<= std_logic_vector(to_unsigned(object_type'pos(A),from_ocb.object'length));
--		from_ocb.num_active_objs	<= std_logic_vector(to_unsigned(3 ,from_ocb.num_active_objs'length));
--		from_ocb.probability		<= std_logic_vector(to_unsigned(0 ,from_ocb.probability'length));
--		wait for period;
--		cmd							<= NOP;
--		
--		wait until busy = '0';
--		
--		cmd							<= EXECUTE;
--		from_ocb.object				<= std_logic_vector(to_unsigned(object_type'pos(B),from_ocb.object'length));
--		from_ocb.num_active_objs	<= std_logic_vector(to_unsigned(3 ,from_ocb.num_active_objs'length));
--		from_ocb.probability		<= std_logic_vector(to_unsigned(0 ,from_ocb.probability'length));
--		wait for period;
--		cmd							<= NOP;
--		
--		wait until busy = '0';
--		
--		cmd							<= EXECUTE;
--		from_ocb.object				<= std_logic_vector(to_unsigned(object_type'pos(A),from_ocb.object'length));
--		from_ocb.num_active_objs	<= std_logic_vector(to_unsigned(6 ,from_ocb.num_active_objs'length));
--		from_ocb.probability		<= std_logic_vector(to_unsigned(0 ,from_ocb.probability'length));
--		wait for period;
--		cmd							<= NOP;
--		
--		wait until busy = '0';
--		
--		cmd							<= EXECUTE;
--		from_ocb.object				<= std_logic_vector(to_unsigned(object_type'pos(OMEGA),from_ocb.object'length));
--		from_ocb.num_active_objs	<= std_logic_vector(to_unsigned(3 ,from_ocb.num_active_objs'length));
--		from_ocb.probability		<= std_logic_vector(to_unsigned(0 ,from_ocb.probability'length));
--		wait for period;
--		cmd							<= NOP;
--		
--		wait on busy until busy = '0' for period;
--		
--		cmd							<= EXECUTE;
--		from_ocb.object				<= std_logic_vector(to_unsigned(object_type'pos(ALFA),from_ocb.object'length));
--		from_ocb.num_active_objs	<= std_logic_vector(to_unsigned(0 ,from_ocb.num_active_objs'length));
--		from_ocb.probability		<= std_logic_vector(to_unsigned(0 ,from_ocb.probability'length));
--		wait for period;
--		
--		cmd							<= NOP;
--		
--		wait for period;
--		
--		cmd							<= EXECUTE;
--		from_ocb.object				<= std_logic_vector(to_unsigned(object_type'pos(A),from_ocb.object'length));
--		from_ocb.num_active_objs	<= std_logic_vector(to_unsigned(3 ,from_ocb.num_active_objs'length));
--		from_ocb.probability		<= std_logic_vector(to_unsigned(0 ,from_ocb.probability'length));
--		wait for period;
--		cmd							<= NOP;
--		
--		wait until busy = '0';
--		
--		cmd							<= EXECUTE;
--		from_ocb.object				<= std_logic_vector(to_unsigned(object_type'pos(B),from_ocb.object'length));
--		from_ocb.num_active_objs	<= std_logic_vector(to_unsigned(1 ,from_ocb.num_active_objs'length));
--		from_ocb.probability		<= std_logic_vector(to_unsigned(0 ,from_ocb.probability'length));
--		wait for period;
--		cmd							<= NOP;
--		
--		wait until busy = '0';
--		
--		cmd							<= EXECUTE;
--		from_ocb.object				<= std_logic_vector(to_unsigned(object_type'pos(C),from_ocb.object'length));
--		from_ocb.num_active_objs	<= std_logic_vector(to_unsigned(1 ,from_ocb.num_active_objs'length));
--		from_ocb.probability		<= std_logic_vector(to_unsigned(0 ,from_ocb.probability'length));
--		wait for period;
--		cmd							<= NOP;
--		
--		wait until busy = '0';
--		
--		cmd							<= CONFIGURE;
--		from_ocb.object				<= std_logic_vector(to_unsigned(object_type'pos(A),from_ocb.object'length));
--		from_ocb.num_active_objs	<= std_logic_vector(to_unsigned(1 ,from_ocb.num_active_objs'length));
--		from_ocb.probability		<= std_logic_vector(to_unsigned(25 ,from_ocb.probability'length));
--		ecu_config_idx				<= std_logic_vector(to_unsigned(0 ,ecu_config_idx'length));
--		wait for period;
--		
--		cmd							<= CONFIGURE;
--		from_ocb.object				<= std_logic_vector(to_unsigned(object_type'pos(B),from_ocb.object'length));
--		from_ocb.num_active_objs	<= std_logic_vector(to_unsigned(1 ,from_ocb.num_active_objs'length));
--		from_ocb.probability		<= std_logic_vector(to_unsigned(25 ,from_ocb.probability'length));
--		ecu_config_idx				<= std_logic_vector(to_unsigned(1 ,ecu_config_idx'length));
--		wait for period;
--		
--		cmd							<= CONFIGURE;
--		from_ocb.object				<= std_logic_vector(to_unsigned(object_type'pos(C),from_ocb.object'length));
--		from_ocb.num_active_objs	<= std_logic_vector(to_unsigned(1 ,from_ocb.num_active_objs'length));
--		from_ocb.probability		<= std_logic_vector(to_unsigned(25 ,from_ocb.probability'length));
--		ecu_config_idx				<= std_logic_vector(to_unsigned(3 ,ecu_config_idx'length));
--		wait for period;
--		
--		cmd							<= CONFIGURE;
--		from_ocb.object				<= std_logic_vector(to_unsigned(object_type'pos(NL),from_ocb.object'length));
--		from_ocb.num_active_objs	<= std_logic_vector(to_unsigned(0 ,from_ocb.num_active_objs'length));
--		from_ocb.probability		<= std_logic_vector(to_unsigned(25 ,from_ocb.probability'length));
--		ecu_config_idx				<= std_logic_vector(to_unsigned(2 ,ecu_config_idx'length));
--		wait for period;
--		
--		cmd							<= CONFIGURE;
--		from_ocb.object				<= std_logic_vector(to_unsigned(object_type'pos(NL),from_ocb.object'length));
--		from_ocb.num_active_objs	<= std_logic_vector(to_unsigned(0 ,from_ocb.num_active_objs'length));
--		from_ocb.probability		<= std_logic_vector(to_unsigned(25 ,from_ocb.probability'length));
--		ecu_config_idx				<= std_logic_vector(to_unsigned(4 ,ecu_config_idx'length));
--		wait for period;
--		
--		cmd							<= EXECUTE;
--		from_ocb.object				<= std_logic_vector(to_unsigned(object_type'pos(A),from_ocb.object'length));
--		from_ocb.num_active_objs	<= std_logic_vector(to_unsigned(4 ,from_ocb.num_active_objs'length));
--		from_ocb.probability		<= std_logic_vector(to_unsigned(0 ,from_ocb.probability'length));
--		wait for period;
--		cmd							<= NOP;
--		
--		wait until busy = '0';
--		
--		cmd							<= EXECUTE;
--		from_ocb.object				<= std_logic_vector(to_unsigned(object_type'pos(B),from_ocb.object'length));
--		from_ocb.num_active_objs	<= std_logic_vector(to_unsigned(4 ,from_ocb.num_active_objs'length));
--		from_ocb.probability		<= std_logic_vector(to_unsigned(0 ,from_ocb.probability'length));
--		wait for period;
--		cmd							<= NOP;
--		
--		wait until busy = '0';
--		
--		cmd							<= EXECUTE;
--		from_ocb.object				<= std_logic_vector(to_unsigned(object_type'pos(NL),from_ocb.object'length));
--		from_ocb.num_active_objs	<= std_logic_vector(to_unsigned(0 ,from_ocb.num_active_objs'length));
--		from_ocb.probability		<= std_logic_vector(to_unsigned(0 ,from_ocb.probability'length));
--		wait for period;
--		cmd							<= NOP;
--		
--		wait until busy = '0';
--		
--		cmd							<= EXECUTE;
--		from_ocb.object				<= std_logic_vector(to_unsigned(object_type'pos(NL),from_ocb.object'length));
--		from_ocb.num_active_objs	<= std_logic_vector(to_unsigned(0 ,from_ocb.num_active_objs'length));
--		from_ocb.probability		<= std_logic_vector(to_unsigned(0 ,from_ocb.probability'length));
--		wait for period;
--		cmd							<= NOP;
--		
--		wait until busy = '0';
--		
--		cmd							<= EXECUTE;
--		from_ocb.object				<= std_logic_vector(to_unsigned(object_type'pos(NL),from_ocb.object'length));
--		from_ocb.num_active_objs	<= std_logic_vector(to_unsigned(0 ,from_ocb.num_active_objs'length));
--		from_ocb.probability		<= std_logic_vector(to_unsigned(0 ,from_ocb.probability'length));
--		wait for period;
--		cmd							<= NOP;
--		
--		wait until busy = '0';
--		
--		cmd							<= EXECUTE;
--		from_ocb.object				<= std_logic_vector(to_unsigned(object_type'pos(NL),from_ocb.object'length));
--		from_ocb.num_active_objs	<= std_logic_vector(to_unsigned(0 ,from_ocb.num_active_objs'length));
--		from_ocb.probability		<= std_logic_vector(to_unsigned(0 ,from_ocb.probability'length));
--		wait for period;
--		cmd							<= NOP;
--		
--		wait until busy = '0';
--		
--		cmd							<= EXECUTE;
--		from_ocb.object				<= std_logic_vector(to_unsigned(object_type'pos(NL),from_ocb.object'length));
--		from_ocb.num_active_objs	<= std_logic_vector(to_unsigned(0 ,from_ocb.num_active_objs'length));
--		from_ocb.probability		<= std_logic_vector(to_unsigned(0 ,from_ocb.probability'length));
--		wait for period;
--		cmd							<= NOP;
		
		wait;
	end process;

end architecture RTL;
