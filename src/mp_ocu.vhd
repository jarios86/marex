library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.numeric_std_unsigned.all;
use ieee.math_real.all;

use work.mp_global_pkg.all;
use work.mp_ocu_pkg.all;

entity mp_ocu is -- Object Container Unit
	port(
		clk				: in std_logic;
		rst_n			: in std_logic;
		rcu_in_if		: in from_rcu_if;
        cmd            	: in ecu_command;
        ready          	: out std_logic;
        rcu_out_if		: out to_rcu_if
	);
end entity mp_ocu;

architecture RTL of mp_ocu is
	
	signal r_members, n_members				: ocu_members;
	signal r_ready, n_ready					: std_logic;
	signal r_num_out_objs, n_num_out_objs	: std_logic_vector (MAX_NUM_OBJECTS_PER_TYPE_BIT_WIDTH-1 downto 0);
	signal r_obj_active, n_obj_active		: std_logic; 
	signal r_obj_queue, n_obj_queue			: std_logic;
	
begin
	
	process (clk, rst_n)
	begin
		if(rst_n = '0') then
			r_members.obj_param.object		<= (others=>'0');
			r_members.reference				<= (others=>'0');
			r_members.obj_param.probability	<= (others=>'0');
			r_members.obj_param.active_objs	<= (others=>'0');
			r_members.obj_param.queued_objs	<= (others=>'0');
			r_num_out_objs					<= (others=>'0');
			r_ready							<= '0';
			r_obj_active					<= '0';
			r_obj_queue						<= '0';
			
		elsif rising_edge(clk) then
			r_members.obj_param.object		<= n_members.obj_param.object;
			r_members.reference				<= n_members.reference;
			r_members.obj_param.probability	<= n_members.obj_param.probability;
			r_members.obj_param.active_objs	<= n_members.obj_param.active_objs;
			r_members.obj_param.queued_objs	<= n_members.obj_param.queued_objs;
			r_num_out_objs					<= n_num_out_objs;
			r_ready							<= n_ready;
			r_obj_active					<= n_obj_active;
			r_obj_queue						<= n_obj_queue;
		end if;
	end process;
	
	
	process (ALL)
	begin
		n_members.obj_param.object		<= r_members.obj_param.object;
		n_members.obj_param.active_objs	<= r_members.obj_param.active_objs;
		n_members.obj_param.queued_objs	<= r_members.obj_param.queued_objs;
		n_members.reference				<= r_members.reference;
		n_members.obj_param.probability	<= r_members.obj_param.probability;
		n_num_out_objs					<= r_num_out_objs;
		n_obj_active					<= '0';
		n_obj_queue						<= '0';
		n_ready							<= r_ready;
				
		case (cmd) is
			when CONFIGURE =>
				n_members.obj_param.object		<= rcu_in_if.object;
				n_members.reference				<= rcu_in_if.num_in_objs;
				n_members.obj_param.probability	<= rcu_in_if.probability;
				n_members.obj_param.active_objs	<= (others=>'0');
				n_members.obj_param.queued_objs	<= (others=>'0');
				if(rcu_in_if.object = std_logic_vector(to_unsigned(special_object_types'pos(NL),rcu_in_if.object'length))) then
					n_ready <= '1';
				end if;
			
			when CATCH =>
				if(rcu_in_if.object = r_members.obj_param.object) and (rcu_in_if.probability <= r_members.obj_param.probability) then
					n_obj_active <= '1';
					if((('0' & r_members.obj_param.active_objs) + ('0' & rcu_in_if.num_in_objs)) > (MAX_NUM_OBJECTS_PER_TYPE-1)) then
						n_members.obj_param.active_objs <= std_logic_vector(to_unsigned(MAX_NUM_OBJECTS_PER_TYPE-1,n_members.obj_param.active_objs'length));
						n_num_out_objs 					<= (MAX_NUM_OBJECTS_PER_TYPE-1) - r_members.obj_param.active_objs;
					else
						n_members.obj_param.active_objs <= r_members.obj_param.active_objs + rcu_in_if.num_in_objs;
						n_num_out_objs 					<= rcu_in_if.num_in_objs;
					end if;
				end if;
				if(n_members.obj_param.active_objs >= r_members.reference) then
					n_ready <= '1';
				else
					n_ready <= '0';
				end if;
				
			when EXECUTE_OPERAND =>
				if(r_ready = '1') then
					n_members.obj_param.active_objs	<= r_members.obj_param.active_objs - r_members.reference;
					--n_busy				<= '1';
				end if;
				if(n_members.obj_param.active_objs >= r_members.reference) then
					n_ready <= '1';
				else
					n_ready <= '0';
				end if;
				
			when EXECUTE_RESULT =>
				if((('0' & r_members.obj_param.active_objs) + ('0' & r_members.reference)) > (MAX_NUM_OBJECTS_PER_TYPE-1)) then
					n_members.obj_param.queued_objs 	<= std_logic_vector(to_unsigned(MAX_NUM_OBJECTS_PER_TYPE-1,n_members.obj_param.queued_objs'length));
				else
					n_members.obj_param.queued_objs 	<= r_members.obj_param.queued_objs + r_members.reference;
				end if;
				
			when DRAIN =>
				if(rcu_in_if.object = r_members.obj_param.object) then
					n_obj_queue 					<= '1';
					n_num_out_objs					<= r_members.obj_param.queued_objs;
					n_members.obj_param.queued_objs	<= (others=>'0');
				end if;
			
			when PURGE =>
				if(rcu_in_if.object = r_members.obj_param.object) then
					n_obj_queue 					<= '1';
					n_obj_active					<= '1';
					n_num_out_objs					<= r_members.obj_param.queued_objs + r_members.obj_param.active_objs;
					n_members.obj_param.queued_objs	<= (others=>'0');
					n_members.obj_param.active_objs	<= (others=>'0');
					n_ready 						<= '0';
				end if;
				
			when CLEAR =>
				n_members.obj_param.queued_objs	<= (others=>'0');
				n_members.obj_param.active_objs	<= (others=>'0');
				if(n_members.obj_param.active_objs >= r_members.reference) then
					n_ready <= '1';
				else
					n_ready <= '0';
				end if;
				
			when NOP =>
				null;
				
		end case;
	end process;
	
	
	process (ALL)
	begin
		ready							<= r_ready;
		rcu_out_if.obj_queue			<= r_obj_queue;
		rcu_out_if.obj_active			<= r_obj_active;
		rcu_out_if.num_out_objs			<= r_num_out_objs;
		rcu_out_if.holding_active_objs	<= (or r_members.obj_param.active_objs);
	end process;
		
end architecture RTL;
