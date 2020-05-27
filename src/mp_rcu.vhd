library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.numeric_std_unsigned.all;
use work.mp_global_pkg.all;
use work.mp_ocu_pkg.all;
use work.mp_rcu_pkg.all;

entity mp_rcu is -- Rule Computing Unit
	port(
		clk 			: in std_logic;
		rst_n 			: in std_logic;
		ocb_in_if		: in from_ocb_if;
		cmd				: in rcu_command;
		ecu_config_idx	: in std_logic_vector(NUM_ECUs_PER_RCU_BIT_WITDH-1 downto 0);
		ocb_out_if		: out to_ocb_if;
 		busy			: out std_logic
	);
end entity mp_rcu;

architecture RTL of mp_rcu is
	
	signal rcu_to_ocu								: from_rcu_if;
	signal ocu_to_rcu								: to_rcu_if_array;
	
	signal n_ecu_cmd								: cmd_array;
	signal ready_ecu								: logic_array;			
	
	signal r_purge, n_purge							: std_logic;
--	signal r_purge_candidate, n_purge_candidate		: std_logic;
	signal r_busy, n_busy							: std_logic;
	
	signal r_num_queued_objs, n_num_queued_objs		: std_logic_vector (MAX_NUM_OBJECTS_PER_TYPE_BIT_WIDTH-1 downto 0);
	signal r_num_active_objs, n_num_active_objs		: std_logic_vector (MAX_NUM_OBJECTS_PER_TYPE_BIT_WIDTH-1 downto 0);
	signal r_obj_queue, n_obj_queue 				: std_logic;
	signal r_obj_active, n_obj_active				: std_logic;
	
	type state is (idle, wait_cmd, collect, deliver, ready_chk);
	signal r_mp_rcu_control_state, n_mp_rcu_control_state : state;
	
	signal r_exe_limit, n_exe_limit		: std_logic_vector(EXECUTION_LIMIT_BITS_WIDTH-1 downto 0);
	signal r_exe_counter, n_exe_counter : std_logic_vector(EXECUTION_LIMIT_BITS_WIDTH-1 downto 0);
	
	
begin
	
	mp_ecu_maker : for ecu_idx in 0 to (MAX_NUM_ECU_OPERANDS_PER_RCU+MAX_NUM_ECU_RESULTS_PER_RCU-1) generate 
    begin
        mp_ecu_inst : entity work.mp_ocu
        	port map(
        		clk        => clk,
        		rst_n      => rst_n,
        		rcu_in_if  => rcu_to_ocu,
        		cmd        => n_ecu_cmd(ecu_idx),
        		ready      => ready_ecu(ecu_idx),
        		rcu_out_if => ocu_to_rcu(ecu_idx)
        	);
    end generate mp_ecu_maker;
    
    
    process (clk, rst_n)
    begin
    	if(rst_n = '0') then
    		r_mp_rcu_control_state 	<= idle;
    		r_num_queued_objs		<= (others=>'0');
    		r_num_active_objs		<= (others=>'0');
    		r_purge					<= '0';
    		r_busy					<= '0';
    		r_exe_limit				<= (others=>'0');
    		r_exe_counter			<= (others=>'0');
--    		r_purge_candidate		<= '0';
    		r_obj_queue				<= '0';
    		r_obj_active			<= '0';
    		
    	elsif rising_edge(clk) then
    		r_mp_rcu_control_state	<= n_mp_rcu_control_state;
    		r_num_queued_objs		<= n_num_queued_objs;
    		r_num_active_objs		<= n_num_active_objs;
    		r_purge					<= n_purge;
    		r_busy					<= n_busy;
    		r_exe_limit				<= n_exe_limit;
    		r_exe_counter			<= n_exe_counter;
--    		r_purge_candidate		<= n_purge_candidate;
    		r_obj_queue				<= n_obj_queue;
    		r_obj_active			<= n_obj_active;
    		
    	end if;	
    end process;
    	
    
    process (ALL)
    	variable all_ocus_ready 		: boolean := true;
    	variable any_ocu_active_holding : boolean := false;
    	
    begin
    	n_mp_rcu_control_state	<= r_mp_rcu_control_state;
    	n_purge					<= r_purge;
    	n_num_queued_objs		<= r_num_queued_objs;
    	n_num_active_objs		<= r_num_active_objs;
    	n_obj_queue				<= '0';
    	n_obj_active			<= '0';
    	n_busy					<= '0';
    	n_exe_limit				<= r_exe_limit;
    	n_exe_counter			<= r_exe_counter;
--    	n_purge_candidate		<= r_purge_candidate;
    	
    	for idx in 0 to (n_ecu_cmd'length-1) loop
    		n_ecu_cmd(idx)	<= NOP;
    		--report "n_ecu_cmd(" &integer'image(idx)& ") --> " & ecu_command'image(n_ecu_cmd(idx));
    	end loop;
    	
    	case (r_mp_rcu_control_state) is
    		when idle =>
    			n_mp_rcu_control_state <= wait_cmd;
    			
    			
    		when wait_cmd =>
    			if(cmd = CONFIGURE) then
    				n_ecu_cmd(to_integer(unsigned(ecu_config_idx)))	<= CONFIGURE;
    				
    			elsif(cmd = CONFIG_LIMIT) then
    				n_exe_limit 	<= ocb_in_if.num_active_objs;
    				n_exe_counter	<= ocb_in_if.num_active_objs;
    				
    			elsif(cmd = EXECUTE) then
    				if(rcu_to_ocu.object = std_logic_vector(to_unsigned(special_object_types'pos(OMEGA),rcu_to_ocu.object'length))) then
	    				all_ocus_ready := true;
						for idx in 0 to (MAX_NUM_ECU_OPERANDS_PER_RCU-1) loop
							if(ready_ecu(idx) = '0') then
								all_ocus_ready := false;
							end if;
						end loop;
	    				
						if((not all_ocus_ready) or (all_ocus_ready and (or r_exe_counter = '0'))) then
							any_ocu_active_holding := false;
		    				for idx in 0 to MAX_NUM_ECU_OPERANDS_PER_RCU-1 loop
			    				if(ocu_to_rcu(idx).holding_active_objs = '1') then
			    					any_ocu_active_holding := true;
			    				end if;
			    			end loop;
			    			
			    			if(any_ocu_active_holding) then
			    				n_purge				<= '1';
			    				n_num_active_objs 	<= std_logic_vector(to_unsigned(1, n_num_active_objs'length));
	    						n_obj_active		<= '1';
			    			end if;
		    			end if;
	    				
--	    				if(r_purge_candidate = '1') then
--	    					n_purge				<= '1';
--	    					n_purge_candidate 	<= '0';
--	    				
--	    				elsif(r_purge = '1') then
--	    					n_num_active_objs 	<= std_logic_vector(to_unsigned(1, n_num_active_objs'length));
--	    					n_obj_active		<= '1';
--	    				end if;
	    				
	    			elsif(rcu_to_ocu.object = std_logic_vector(to_unsigned(special_object_types'pos(ALFA),rcu_to_ocu.object'length))) then
	    				for idx in 0 to (MAX_NUM_ECU_OPERANDS_PER_RCU+MAX_NUM_ECU_RESULTS_PER_RCU-1) loop
	    					n_ecu_cmd(idx)	<= CLEAR;    				
	    				end loop;
	    				n_purge <= '0';
	    				n_exe_counter <= r_exe_limit;
	    				
	    			--elsif(rcu_to_ocu.object = std_logic_vector(to_unsigned(special_object_types'pos(DELTA),rcu_to_ocu.object'length))) then
	    				--null;
	    				
	    			elsif(rcu_to_ocu.object = std_logic_vector(to_unsigned(special_object_types'pos(NL),rcu_to_ocu.object'length))) then
	    				n_busy <= '1';
	    				n_mp_rcu_control_state	<= ready_chk;
	    				
	    			elsif(r_purge = '1') then
	    				n_busy <= '1';
	    				for idx in 0 to (MAX_NUM_ECU_OPERANDS_PER_RCU+MAX_NUM_ECU_RESULTS_PER_RCU-1) loop
    						n_ecu_cmd(idx) <= PURGE;
    					end loop;
    					n_mp_rcu_control_state <= collect;
    					
	    			else
	    				n_busy <= '1';
    					for idx in MAX_NUM_ECU_OPERANDS_PER_RCU to (MAX_NUM_ECU_OPERANDS_PER_RCU+MAX_NUM_ECU_RESULTS_PER_RCU-1) loop
    						n_ecu_cmd(idx) <= DRAIN;
    					end loop;
    					n_mp_rcu_control_state <= collect;
    				end if;
    			end if;
    		
    		
    		when collect =>
    			n_busy <= '1';
    			for idx in MAX_NUM_ECU_OPERANDS_PER_RCU to (MAX_NUM_ECU_OPERANDS_PER_RCU+MAX_NUM_ECU_RESULTS_PER_RCU-1) loop
    				if(ocu_to_rcu(idx).obj_queue = '1') then
    					n_num_queued_objs 	<= ocu_to_rcu(idx).num_out_objs;
    					n_obj_queue			<= '1';
    				end if;
    			end loop;
    			
    			if(r_purge = '1') then
    				for idx in 0 to MAX_NUM_ECU_OPERANDS_PER_RCU-1 loop
	    				if(ocu_to_rcu(idx).obj_active = '1') then
	    					n_num_active_objs 	<= ocu_to_rcu(idx).num_out_objs;
	    					n_obj_active		<= '1';
	    				end if;
	    			end loop;
	    			n_mp_rcu_control_state	<= wait_cmd;
    				
    			else
    				for idx in 0 to (MAX_NUM_ECU_OPERANDS_PER_RCU-1) loop
	    				n_ecu_cmd(idx)	<= CATCH;
	    			end loop;
    				n_mp_rcu_control_state	<= deliver;
				end if;
    		
    		
			when deliver =>
				n_busy <= '1';
    			for idx in 0 to (MAX_NUM_ECU_OPERANDS_PER_RCU-1) loop
    				if(ocu_to_rcu(idx).obj_active = '1') then
    					n_num_active_objs 	<= ocu_to_rcu(idx).num_out_objs;
    					n_obj_active		<= '1';
--    					n_purge_candidate	<= '1';
    				end if;
    			end loop;
				n_mp_rcu_control_state	<= ready_chk;
				
				
			when ready_chk =>
				all_ocus_ready := true;
				for idx in 0 to (MAX_NUM_ECU_OPERANDS_PER_RCU-1) loop
					if(ready_ecu(idx) = '0') then
						all_ocus_ready := false;
					end if;
				end loop;
				if(all_ocus_ready and r_exe_counter /= std_logic_vector(to_unsigned(0,r_exe_counter'length))) then
					for idx in 0 to (MAX_NUM_ECU_OPERANDS_PER_RCU-1) loop
						n_ecu_cmd(idx)	<= EXECUTE_OPERAND;
					end loop;
					for idx in MAX_NUM_ECU_OPERANDS_PER_RCU to (MAX_NUM_ECU_OPERANDS_PER_RCU+MAX_NUM_ECU_RESULTS_PER_RCU-1) loop
						n_ecu_cmd(idx)	<= EXECUTE_RESULT;
					end loop;
					if(and r_exe_counter /= '1') then
						n_exe_counter <= r_exe_counter - 1;
					end if;
				end if;
    			n_mp_rcu_control_state	<= wait_cmd;
    			
    	end case;
    end process;
    
    
    process (ALL)
    begin
    	rcu_to_ocu.object 			<= ocb_in_if.object;
		rcu_to_ocu.num_in_objs 		<= ocb_in_if.num_active_objs;
		rcu_to_ocu.probability 		<= ocb_in_if.probability;
	
    	ocb_out_if.obj_active		<= r_obj_active;
    	ocb_out_if.obj_queue		<= r_obj_queue;
    	ocb_out_if.num_active_objs	<= r_num_active_objs;
		ocb_out_if.num_queued_objs 	<= r_num_queued_objs;
		ocb_out_if.purge			<= r_purge;
		busy						<= r_busy; 	
    end process;    	

end architecture RTL;
