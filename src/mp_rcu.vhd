library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.mp_global_pkg.all;
use work.mp_ecu_pkg.all;
use work.mp_rcu_pkg.all;

entity mp_rcu is -- Rule Computing Unit
	port(
		clk 			: in std_logic;
		rst_n 			: in std_logic;
		elt_type		: in std_logic_vector(ELEMENT_TYPE_BITS_WIDTH-1 downto 0);
		num_in_elts 	: in std_logic_vector (NUM_ELEMENTS_PER_TYPE_BITS_WIDTH-1 downto 0);
		cmd				: in rcu_command;
		ecu_config_idx	: in std_logic_vector(NUM_ECUs_PER_RCU_BITS_WITDH-1 downto 0);
		elt_queue		: out std_logic;
		num_queued_elts	: out std_logic_vector (NUM_ELEMENTS_PER_TYPE_BITS_WIDTH-1 downto 0);
		elt_actual		: out std_logic;
		num_actual_elts	: out std_logic_vector (NUM_ELEMENTS_PER_TYPE_BITS_WIDTH-1 downto 0);
		busy			: out std_logic
	);
end entity mp_rcu;

architecture RTL of mp_rcu is
	
	--signal r_elt_type, n_elt_type 					: std_logic_vector(ELEMENT_TYPE_BITS_WIDTH-1 downto 0);
	signal n_elt_type 								: std_logic_vector(ELEMENT_TYPE_BITS_WIDTH-1 downto 0);
	--signal r_num_in_elts, n_num_in_elts 			: std_logic_vector(NUM_ELEMENTS_PER_TYPE_BITS_WIDTH-1 downto 0);
	signal n_num_in_elts 							: std_logic_vector(NUM_ELEMENTS_PER_TYPE_BITS_WIDTH-1 downto 0);
	--signal r_ecu_cmd, n_ecu_cmd						: cmd_array;
	signal n_ecu_cmd								: cmd_array;
	--signal r_ecu_config_idx, n_ecu_config_idx		: std_logic_vector(NUM_ECUs_PER_RCU_BITS_WITDH-1 downto 0);
	signal ready_ecu								: logic_array;			
	signal elt_queue_ecu							: logic_array;
	signal elt_actual_ecu							: logic_array;
	signal num_out_elts_ecu							: logic_vector_array;
	
	signal r_purge, n_purge							: std_logic;
	signal r_busy, n_busy							: std_logic;
	
	signal r_num_queued_elts, n_num_queued_elts		: std_logic_vector (NUM_ELEMENTS_PER_TYPE_BITS_WIDTH-1 downto 0);
	signal r_num_actual_elts, n_num_actual_elts		: std_logic_vector (NUM_ELEMENTS_PER_TYPE_BITS_WIDTH-1 downto 0);
	signal n_elt_queue 								: std_logic;
	signal n_elt_actual								: std_logic;
	
	type state is (idle, wait_cmd, collect, deliver, ready_chk);
	signal r_mp_rcu_control_state, n_mp_rcu_control_state : state;
	
	
begin
	
	mp_ecu_maker : for ecu_idx in 0 to (MAX_NUM_ECU_OPERANDS_PER_RCU+MAX_NUM_ECU_RESULTS_PER_RCU-1) generate 
    BEGIN
        mp_ecu_inst : ENTITY work.mp_ecu
        	port map(
        		clk          => clk,
        		rst_n        => rst_n,
        		elt_type     => n_elt_type,
        		num_in_elts  => n_num_in_elts,
        		cmd          => n_ecu_cmd(ecu_idx),
        		ready        => ready_ecu(ecu_idx),
        		elt_queue    => elt_queue_ecu(ecu_idx),
        		elt_actual   => elt_actual_ecu(ecu_idx),
        		num_out_elts => num_out_elts_ecu(ecu_idx)
        	);
    end generate mp_ecu_maker;
    
    
    process (clk, rst_n)
    begin
    	if(rst_n = '0') then
    		r_mp_rcu_control_state 	<= idle;
    		--r_elt_type				<= (others=>'0');
    		r_num_queued_elts		<= (others=>'0');
    		r_num_actual_elts		<= (others=>'0');
    		--r_elt_queue				<= '0';
    		r_purge					<= '0';
    		--r_elt_actual			<= '0';
    		r_busy					<= '0';
    		--r_num_in_elts			<= (others=>'0');
    		
--    		for idx in 0 to r_num_in_elts'length-1 loop
--    			r_num_in_elts(idx)	<= (others=>'0');
--    		end loop;
--    		for idx in 0 to r_ecu_cmd'length-1 loop
--    			r_ecu_cmd(idx)	<= NOP;
--    		end loop;
    		
    	elsif rising_edge(clk) then
    		r_mp_rcu_control_state	<= n_mp_rcu_control_state;
    		--r_elt_type			<= n_elt_type;
    		--r_num_in_elts			<= n_num_in_elts;
    		--r_ecu_cmd				<= n_ecu_cmd;
    		r_num_queued_elts		<= n_num_queued_elts;
    		r_num_actual_elts		<= n_num_actual_elts;
    		--r_elt_queue				<= n_elt_queue;
    		r_purge					<= n_purge;
    		--r_elt_actual			<= n_elt_actual;
    		r_busy					<= n_busy;
    		--r_num_in_elts			<= n_num_in_elts;
    		
    	end if;	
    end process;
    	
    
    process (ALL)
    	variable all_ecus_ready : boolean := true;
    	
    begin
    	n_mp_rcu_control_state	<= r_mp_rcu_control_state;
    	n_elt_type				<= elt_type; --r_elt_type;
    	n_num_in_elts 			<= num_in_elts;
    	n_purge					<= r_purge;
    	n_num_queued_elts		<= r_num_queued_elts;
    	n_num_actual_elts		<= r_num_actual_elts;
    	n_elt_queue				<= '0';
    	n_elt_actual			<= '0';
    	n_busy					<= '0';
    	
--    	for idx in 0 to n_num_in_elts'length-1 loop
--    		n_num_in_elts(idx)	<= r_num_in_elts(idx);
--    	end loop;
    	
    	for idx in 0 to n_ecu_cmd'length-1 loop
    		n_ecu_cmd(idx)	<= NOP;
    	end loop;
    	
    	case (r_mp_rcu_control_state) is
    		when idle =>
    			n_mp_rcu_control_state <= wait_cmd;
    			
    			
    		when wait_cmd =>
    			if(cmd = CONFIGURE) then
    				--n_elt_type									<= elt_type;
    				--n_num_in_elts									<= num_in_elts;
    				n_ecu_cmd(to_integer(unsigned(ecu_config_idx)))	<= CONFIGURE;
    				
    			elsif(cmd = CLEAR) then
    				for idx in 0 to (MAX_NUM_ECU_OPERANDS_PER_RCU+MAX_NUM_ECU_RESULTS_PER_RCU-1) loop
	    				n_ecu_cmd(idx)	<= CLEAR;    				
    				end loop;
    				n_purge <= '0';
    				
    			elsif(cmd = EXECUTE) then
    				if(elt_type = std_logic_vector(to_unsigned(special_object_types'pos(OMEGA),elt_type'length))) then
	    				n_purge	<= '1';
	    				
	    			elsif(elt_type = std_logic_vector(to_unsigned(special_object_types'pos(ALFA),elt_type'length))) then
	    				null; --TODO implementación futura
	    				
	    			elsif(elt_type = std_logic_vector(to_unsigned(special_object_types'pos(DELTA),elt_type'length))) then
	    				null; --TODO implementación futura
	    				
	    			elsif(elt_type = std_logic_vector(to_unsigned(special_object_types'pos(NL),elt_type'length))) then
	    				null; --TODO implementación futura
	    				
	    			elsif(r_purge = '1') then
	    				n_busy <= '1';
	    				for idx in 0 to (MAX_NUM_ECU_OPERANDS_PER_RCU+MAX_NUM_ECU_RESULTS_PER_RCU-1) loop
    						n_ecu_cmd(idx) <= PURGE;
    					end loop;
    					n_mp_rcu_control_state <= collect;
    					
	    			else
	    				n_busy <= '1';
	    				--n_num_in_elts <= num_in_elts;
    					for idx in MAX_NUM_ECU_OPERANDS_PER_RCU to (MAX_NUM_ECU_OPERANDS_PER_RCU+MAX_NUM_ECU_RESULTS_PER_RCU-1) loop
    						n_ecu_cmd(idx) <= DRAIN;
    					end loop;
    					n_mp_rcu_control_state <= collect;
    				end if;
    			end if;
    		
    		
    		when collect =>
    			n_busy <= '1';
    			for idx in MAX_NUM_ECU_OPERANDS_PER_RCU to (MAX_NUM_ECU_OPERANDS_PER_RCU+MAX_NUM_ECU_RESULTS_PER_RCU-1) loop
    				if(elt_queue_ecu(idx) = '1') then
    					n_num_queued_elts 	<= num_out_elts_ecu(idx);
    					n_elt_queue			<= '1';
    				end if;
    			end loop;
    			
    			if(r_purge = '1') then
    				for idx in 0 to MAX_NUM_ECU_OPERANDS_PER_RCU-1 loop
	    				if(elt_actual_ecu(idx) = '1') then
	    					n_num_actual_elts 	<= num_out_elts_ecu(idx);
	    					n_elt_actual		<= '1';
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
    				if(elt_actual_ecu(idx) = '1') then
    					n_num_actual_elts 	<= num_out_elts_ecu(idx); -- r_num_in_elts - num_out_elts_ecu(idx)
    					n_elt_actual		<= '1';
    				end if;
    			end loop;
				n_mp_rcu_control_state	<= ready_chk;
				
				
			when ready_chk =>
				--n_busy <= '1';
				all_ecus_ready := true;
				for idx in 0 to (MAX_NUM_ECU_OPERANDS_PER_RCU-1) loop
					if(ready_ecu(idx) = '0') then
						all_ecus_ready := false;
					end if;
				end loop;
				if(all_ecus_ready) then
					for idx in 0 to (MAX_NUM_ECU_OPERANDS_PER_RCU-1) loop
						n_ecu_cmd(idx)	<= EXECUTE_OPERAND;
					end loop;
					for idx in MAX_NUM_ECU_OPERANDS_PER_RCU to (MAX_NUM_ECU_OPERANDS_PER_RCU+MAX_NUM_ECU_RESULTS_PER_RCU-1) loop
						n_ecu_cmd(idx)	<= EXECUTE_RESULT;
					end loop;
				end if;
    			n_mp_rcu_control_state	<= wait_cmd;			
				
    	end case;
    end process;
    
    
    process (ALL)
    begin
    	elt_actual		<= n_elt_actual;		-- TODO Deberían estas señales estar conectadas directamente a la señal n_ mejor que
    	elt_queue 		<= n_elt_queue;			-- a la señal del registro r_ ???. Idem para la ECU
    	num_actual_elts	<= n_num_actual_elts;
		num_queued_elts <= n_num_queued_elts;
		busy			<= r_busy; 	
    end process;    	

end architecture RTL;
