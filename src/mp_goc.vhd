library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.numeric_std_unsigned.all;

use work.mp_goc_pkg.all;
use work.mp_global_pkg.all;
use work.mp_rcu_pkg.all;
use work.mp_ocu_pkg.all;

entity mp_goc is
	port(
		clk 			: in std_logic;
		rst_n 			: in std_logic;
		ocb_in_if		: in obj_parameters;
		ocb_out_if		: out obj_parameters;
		read			: in std_logic;
		write			: in std_logic;
		req_finish		: out std_logic;
		req_comp_step 	: out std_logic
	);
end entity mp_goc;

architecture RTL of mp_goc is
	
	signal mem_objects     : elt_logic_vector_array;
	signal mem_active_objs : num_elt_logic_vector_array;
	signal mem_queued_objs : num_elt_logic_vector_array;
	signal mem_probability : prob_logic_vector_array;

	signal r_object_OCU : obj_parameters;
	
	signal r_read_idx	: std_logic_vector(NUM_OBJECT_TYPES_BIT_WIDTH - 1 downto 0);
	signal r_write_idx 	: std_logic_vector(NUM_OBJECT_TYPES_BIT_WIDTH - 1 downto 0);
	
	signal r_comp_step_flag	: std_logic;
	signal r_req_comp_step	: std_logic;
	signal r_req_finish		: std_logic;
	
	--signal r_wr_random, n_wr_random	: std_logic_vector(NUM_OBJECT_TYPES_BIT_WIDTH-1 downto 0) := (others=>'0'); -- Init only for test
	--signal n_wr_rand_feedback		: std_logic := '0'; -- Init only for test
	
	--signal r_rd_random, n_rd_random	: std_logic_vector(NUM_OBJECT_TYPES_BIT_WIDTH-1 downto 0) := (others=>'0'); -- Init only for test
	--signal n_rd_rand_feedback		: std_logic := '0'; -- Init only for test
	
	signal r_pumping_counter		: std_logic_vector(MAX_NUM_RULES_BIT_WIDTH-1 downto 0);
	signal r_filling_NL				: std_logic;
	
begin
	
	process (clk, rst_n)
		variable queued_accum 	: integer;
		variable active_accum 	: integer;
		variable no_queued		: boolean;
	begin
		if(rst_n = '0') then
			r_read_idx 					<= (others=>'0');
			r_write_idx					<= (others=>'0');
			r_object_OCU.object			<= (others=>'0');
			r_object_OCU.active_objs	<= (others=>'0');
			r_object_OCU.queued_objs	<= (others=>'0');
			r_object_OCU.probability	<= (others=>'0');
			--mem_objects			<= (others=>(others=>'0'));
			--mem_probability 	<= (others=>(others=>'0'));
			--mem_active_objs		<= (others=>(others=>'0'));
			--mem_queued_objs 	<= (others=>(others=>'0'));
			r_comp_step_flag	<= '0';
			r_req_comp_step		<= '0';
			r_req_finish		<= '0';
			--r_wr_random			<= (others=>'1');
			--r_rd_random			<= (others=>'1');
			r_pumping_counter	<= (others=>'0');
			r_filling_NL		<= '0';

		elsif rising_edge(clk) then
			if(r_req_comp_step = '1') then
				no_queued := true;
				for idx in 0 to (NUM_OBJECT_TYPES-1) loop
					queued_accum := to_integer(mem_queued_objs(idx));
					active_accum := to_integer(mem_active_objs(idx));
					if(queued_accum /= 0) then
						no_queued := false;
					end if;
					mem_queued_objs(idx) <= (others=>'0');
					mem_active_objs(idx) <= std_logic_vector(to_unsigned(queued_accum + active_accum,mem_active_objs(idx)'length));
				end loop;
				if(no_queued) then
					r_req_finish <= '1';
				end if;
				r_req_comp_step 	<= '0';
				r_write_idx 		<= (others=>'0');
				r_read_idx			<= (others=>'0');
				r_pumping_counter	<= (others=>'0');
				r_filling_NL		<= '0';
			end if;
			
			if(write = '1') then
				mem_objects(to_integer(unsigned(r_write_idx)))		<= ocb_in_if.object;
				if(ocb_in_if.object = std_logic_vector(to_unsigned(special_object_types'pos(OMEGA),ocb_in_if.object'length))) then
					mem_active_objs(to_integer(unsigned(r_write_idx)))	<= (others=>'0');
					mem_queued_objs(to_integer(unsigned(r_write_idx)))	<= (others=>'0');
					mem_probability(to_integer(unsigned(r_write_idx)))	<= (others=>'0');
				else
					mem_active_objs(to_integer(unsigned(r_write_idx)))	<= ocb_in_if.active_objs;
					mem_queued_objs(to_integer(unsigned(r_write_idx)))	<= ocb_in_if.queued_objs;
					mem_probability(to_integer(unsigned(r_write_idx)))	<= ocb_in_if.probability;
				end if;
				
				if(r_comp_step_flag = '1') then
					if(ocb_in_if.active_objs /= mem_active_objs(to_integer(unsigned(r_write_idx))) or 
						ocb_in_if.queued_objs /= mem_queued_objs(to_integer(unsigned(r_write_idx)))
					) then
						r_comp_step_flag <= '0';
					end if;
				end if;
				
				if(ocb_in_if.object = std_logic_vector(to_unsigned(special_object_types'pos(OMEGA),ocb_in_if.object'length)) and 
					r_comp_step_flag = '1' and (or ocb_in_if.active_objs = '0')
				) then
					r_req_comp_step 	<= '1';
				end if;
				
				if(r_write_idx = std_logic_vector(to_unsigned(NUM_OBJECT_TYPES-1,r_write_idx'length))) then
					r_write_idx	<= (others=>'0');
					--r_wr_random	<= (others=>'1');
					report "Reseting write_idx ptr but OMEGA object has not been inserted" severity error;
					
				elsif(ocb_in_if.object = std_logic_vector(to_unsigned(special_object_types'pos(OMEGA),ocb_in_if.object'length))) then
					r_write_idx	<= (others=>'0');
					--r_wr_random	<= (others=>'1');
					report "Reseting write_idx ptr";
					
				else
					--r_write_idx <= n_wr_random;
					r_write_idx <= r_write_idx + 1;
					--r_wr_random	<= n_wr_random;
				end if;
			end if;
			
			if(read = '1') then
				r_pumping_counter <= r_pumping_counter + 1;
				
				if(r_pumping_counter = std_logic_vector(to_unsigned(MAX_NUM_RULES+2, r_pumping_counter'length))) then -- MAX_NUM_RULES+1 ensure first read OCU has been written
					r_pumping_counter	<= (others=>'0');
					r_filling_NL 		<= '0';
				end if;
				
				if(mem_objects(to_integer(unsigned(r_read_idx))) = std_logic_vector(to_unsigned(special_object_types'pos(ALFA),ocb_in_if.object'length))) then
					r_req_finish <= '0';
				end if;
				
				if(r_filling_NL = '1') then
					r_object_OCU.object			<= std_logic_vector(to_unsigned(special_object_types'pos(NL),r_object_OCU.object'length));
					r_object_OCU.active_objs	<= std_logic_vector(to_unsigned(0, r_object_OCU.active_objs'length));
					r_object_OCU.queued_objs	<= std_logic_vector(to_unsigned(0, r_object_OCU.queued_objs'length));
					r_object_OCU.probability	<= std_logic_vector(to_unsigned(0, r_object_OCU.probability'length));
				
				else
					r_object_OCU.object			<= mem_objects(to_integer(unsigned(r_read_idx)));
					r_object_OCU.active_objs	<= mem_active_objs(to_integer(unsigned(r_read_idx)));
					r_object_OCU.queued_objs	<= mem_queued_objs(to_integer(unsigned(r_read_idx)));
					r_object_OCU.probability	<= mem_probability(to_integer(unsigned(r_read_idx)));
				
					if(mem_objects(to_integer(unsigned(r_read_idx))) = std_logic_vector(to_unsigned(special_object_types'pos(OMEGA),ocb_in_if.object'length))) then
						r_comp_step_flag <= '1';
						r_read_idx 		 <= std_logic_vector(to_unsigned(1, r_read_idx'length));
						if(r_pumping_counter <= std_logic_vector(to_unsigned(MAX_NUM_RULES, r_pumping_counter'length))) then
							r_filling_NL <= '1';
							report "Filling with NL objects";
						end if;
					else
						if(r_read_idx = std_logic_vector(to_unsigned(NUM_OBJECT_TYPES-1, r_read_idx'length))) then
							r_read_idx	<= (others=>'0');
							report "Reseting read_idx ptr but OMEGA object has not been read" severity error;
							
						else
							--r_read_idx 	<= n_rd_random;
							r_read_idx 	<= r_read_idx + 1;
							--r_rd_random <= n_rd_random;
						end if;
					end if;
				end if;
			end if;
		end if;
	end process;
	
	
--	for idx in 0 to (ELEMENT_TYPE_BITS_WIDTH-1) loop
--			if(idx /= 1) then
--				n_wr_rand_feedback <= n_wr_rand_feedback xor r_wr_random(idx);
--				n_rd_rand_feedback <= n_rd_rand_feedback xor r_rd_random(idx);
--			end if;
--	end loop;
--	n_wr_rand_feedback  <= r_wr_random(2) xor r_wr_random(0);
--	n_wr_random			<= n_wr_rand_feedback & r_wr_random(NUM_OBJECT_TYPES_BIT_WIDTH-1 downto 1);
--	n_rd_rand_feedback	<= r_rd_random(2) xor r_rd_random(0);
--	n_rd_random			<= n_rd_rand_feedback & r_rd_random(NUM_OBJECT_TYPES_BIT_WIDTH-1 downto 1);
	
	
	process (ALL)
	begin
		ocb_out_if.object		<= r_object_OCU.object;
		ocb_out_if.active_objs	<= r_object_OCU.active_objs;
		ocb_out_if.queued_objs	<= r_object_OCU.queued_objs;
		ocb_out_if.probability	<= r_object_OCU.probability;
		req_comp_step			<= r_req_comp_step;
		req_finish				<= r_req_finish;
	end process;
end architecture RTL;
