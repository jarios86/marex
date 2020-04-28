library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.mp_goc_pkg.all;
use work.mp_global_pkg.all;
use work.mp_ocu_pkg.all;

entity mp_goc_tb is
end entity mp_goc_tb;

architecture RTL of mp_goc_tb is
	
	type object_type 		is (NL, ALFA, OMEGA, DELTA, A, B, C, D); -- El número de object_types debe coincidir con la constante MAX_NUM_OBJECTS_TYPES
	constant period : time := 20 ns;
	
	signal clk           : std_logic;
	signal rst_n         : std_logic;
	signal ocb_in_if     : obj_parameters;
	signal ocb_out_if    : obj_parameters;
	signal read          : std_logic;
	signal write         : std_logic;
	signal req_finish    : std_logic;
	signal req_comp_step : std_logic;

	--type objetc_array 		is array (0 to NUM_OBJECT_TYPES-2) of object_type;
	type integer_array 		is array (0 to NUM_OBJECT_TYPES-2) of integer;
		
	signal objects_GOC		: integer_array := (object_type'pos(ALFA), object_type'pos(A), object_type'pos(B), object_type'pos(C),
		object_type'pos(D), object_type'pos(DELTA), object_type'pos(OMEGA)
	);
	signal probability_GOC	: integer_array := (0, 1, 1, 1, 1, 1, 0);
	--signal reference_GOC	: integer_array := (0, 2, 1, 3, 0, 1, 0);
	signal active_GOC		: integer_array := (0, 7, 5, 0, 0, 0, 0);
	signal queued_GOC		: integer_array := (0, 0, 0, 0, 0, 0, 0);
	
begin
	
	inst : entity work.mp_goc
		port map(
			clk           => clk,
			rst_n         => rst_n,
			ocb_in_if     => ocb_in_if,
			ocb_out_if    => ocb_out_if,
			read          => read,
			write         => write,
			req_finish    => req_finish,
			req_comp_step => req_comp_step
		);
		
	clock_driver : process
	begin
		clk <= '0';
		wait for period / 2;
		clk <= '1';
		wait for period / 2;
	end process clock_driver;
	
	
	stim_proc : process
		variable wr_idx	: integer;
	begin
		write <= '0';
		read  <= '0';
		
		-- hold reset state.
		wait for period/2;
		rst_n <= '0';
		wait for period;
		rst_n <= '1';
		wait for period;
		
		-- insert stimulus here
		for wr_idx in 0 to (NUM_OBJECT_TYPES-2) loop
			write 					<= '1';
			ocb_in_if.object		<= std_logic_vector(to_unsigned(objects_GOC(wr_idx), ocb_in_if.object'length));
			ocb_in_if.probability	<= std_logic_vector(to_unsigned(probability_GOC(wr_idx), ocb_in_if.probability'length));
			ocb_in_if.active_objs	<= std_logic_vector(to_unsigned(active_GOC(wr_idx), ocb_in_if.active_objs'length));
			ocb_in_if.queued_objs	<= std_logic_vector(to_unsigned(queued_GOC(wr_idx), ocb_in_if.queued_objs'length));
			wait for period;
		end loop;
		ocb_in_if.object		<= (others=>'0');
		ocb_in_if.probability	<= (others=>'0');
		ocb_in_if.active_objs	<= (others=>'0');
		ocb_in_if.queued_objs	<= (others=>'0');
		write <= '0';
		wait for period;
		
		wr_idx := 0;
		for idx in 0 to 20 loop
			write 	<= '0';
			read 	<= '0';
			if(req_comp_step = '0') then
				read <= '1';
				if(idx > MAX_NUM_RULES and wr_idx < 7) then
					write <= '1';
					ocb_in_if.object		<= std_logic_vector(to_unsigned(objects_GOC(wr_idx), ocb_in_if.object'length));
					ocb_in_if.probability	<= std_logic_vector(to_unsigned(probability_GOC(wr_idx), ocb_in_if.probability'length));
					ocb_in_if.active_objs	<= std_logic_vector(to_unsigned(active_GOC(wr_idx), ocb_in_if.active_objs'length));
					ocb_in_if.queued_objs	<= std_logic_vector(to_unsigned(queued_GOC(wr_idx), ocb_in_if.queued_objs'length));
					wr_idx := wr_idx +1;
				end if;
			end if;
			wait for period;
		end loop;
		ocb_in_if.object		<= (others=>'0');
		ocb_in_if.probability	<= (others=>'0');
		ocb_in_if.active_objs	<= (others=>'0');
		ocb_in_if.queued_objs	<= (others=>'0');
		write <= '0';
		read <= '0';
		wait for period;
		
		wr_idx := 0;
		for idx in 0 to 20 loop
			write 	<= '0';
			read 	<= '0';
			if(req_comp_step = '0') then
				read <= '1';
				if(idx > MAX_NUM_RULES and wr_idx < 7) then
					write <= '1';
					ocb_in_if.object		<= std_logic_vector(to_unsigned(objects_GOC(wr_idx), ocb_in_if.object'length));
					ocb_in_if.probability	<= std_logic_vector(to_unsigned(probability_GOC(wr_idx), ocb_in_if.probability'length));
					ocb_in_if.active_objs	<= std_logic_vector(to_unsigned(active_GOC(wr_idx), ocb_in_if.active_objs'length));
					ocb_in_if.queued_objs	<= std_logic_vector(to_unsigned(queued_GOC(wr_idx), ocb_in_if.queued_objs'length));
					wr_idx := wr_idx +1;
				end if;
			end if;
			wait for period;
		end loop;
		ocb_in_if.object		<= (others=>'0');
		ocb_in_if.probability	<= (others=>'0');
		ocb_in_if.active_objs	<= (others=>'0');
		ocb_in_if.queued_objs	<= (others=>'0');
		write <= '0';
		read <= '0';
		
		wait;
	end process;
end architecture RTL;
