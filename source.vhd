----------------------------------------------------------------------------------
----- Company: Politecnico di Milano
----- Create Date: 07.03.2019 18:32:21
----- Module Name: project_reti_logiche - FSM
-- -- Project Name: Prova Finale Reti Logiche AA 2018/2019
----- Engineers: 
-- Daniele Nicolò  - MATR. 846897 - COD. PERSONA 10527191 -  daniele.nicolo@mail.polimi.it
-- Gioele Mombelli - MATR. 845899 - COD. PERSONA 10520552 - gioele.mombelli@mail.polimi.it
----- Description:
-- Hardware component that determines the nearest centroid to a point (called "observer") on a 256x256 grid.
-- More  information,  such  as RAM's  addresses  description,  a detailed  explanation  of  the  algorithm 
-- and specifications of  the  signals and  the  general  behaviour  of  the machine is   available  in the
-- official documentation (Italian language only).
----------------------------------------------------------------------------------
----------------------------------------------------------------------------------


------ Libraries and entity ------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL; --Needed to perform arithmetical operations on some values.

entity project_reti_logiche is
port (   
		i_clk          : in  std_logic;  -- CLOCK signal 
		i_start        : in  std_logic;  -- START signal 
		i_rst          : in  std_logic;  -- RESET signal
		o_done         : out std_logic;  -- DONE  signal
		   
		i_data         : in  std_logic_vector(7 downto 0);   --[RAM]: input  
		o_address      : out std_logic_vector(15 downto 0);  --[RAM]: output                
		o_en           : out std_logic;                      --[RAM]: output
		o_we           : out std_logic;                      --[RAM]: output
		o_data         : out std_logic_vector (7 downto 0)   --[RAM]: output
	); 

end project_reti_logiche;

------ Architecture ------


architecture FSM of project_reti_logiche is

    -- States:
    -- For a complete description of the states, please read the documentation.

    type state_type is(
        
            wait_start,
            start,
            x_request,
            x_received,
            y_request,
            y_received,
            mask_request,
            mask_received,
            loop_start,
            valid_centroid,
            x_request_centroid,
            x_centroid_received,
            y_request_centroid,
            y_centroid_received,
            x_distance,
            check_x,
            y_distance,
            check_y,
            manhattan_distance,
            distance_difference,
            check_distance,
            add_centroid,
            added_centroid,
            reset_mask,
            send_data,
            end_computation,
            lowered_start
            
            );
            
    -- Signals:
    -- For a complete description of the signals, please read the documentation.
    
    signal current_state, next_state : state_type; --States of the FSM.
    signal x, y, next_x, next_y : std_logic_vector(8 downto 0); --Coordinates of the observed point.
    signal mask, next_mask : std_logic_vector(7 downto 0); --Input mask.
    signal x_centroid, y_centroid, next_x_centroid, next_y_centroid : std_logic_vector(8 downto 0); --Coordinates of the current centroid.
    signal current_distance, next_current_distance : std_logic_vector(9 downto 0); --Distance of the current centroid from the point.
    signal lowest_distance, next_lowest_distance : std_logic_vector(9 downto 0); --Minimum distance.
    signal mask_out, next_mask_out : std_logic_vector(7 downto 0); --Output mask.
    signal diff_x, diff_y, next_diff_x, next_diff_y : std_logic_vector(8 downto 0);--Difference between X and Y of the point and the centroid. They are used in the computation of the Manhattan distance.
    signal i, next_i : std_logic_vector(4 downto 0); --Index of the loop that iterates through the centroids.
    signal distance_diff, next_distance_diff : std_logic_vector(9 downto 0); --Difference between the current distance and the lowest distance determined until now.
    
-- Processes:
    
begin

        --"register" process: describes the registers.
        
        registers: process(i_clk, i_rst)
            begin
            
            --If the RESET signal is received, every internal signal must be initialized with the default value. The FSM then jumps to the "wait_start" state.
                if i_rst = '1' then
                    current_state <= wait_start;
                    x <= "000000000";
                    y <= "000000000";
                    mask <= "00000000";
                    x_centroid <= "000000000";
                    y_centroid <= "000000000";
                    mask_out <= "00000000";
                    diff_x <= "000000000";
                    diff_y <= "000000000";
                    current_distance <= "0000000000";
                    distance_diff <= "0000000000";
                    lowest_distance <= "0111111111"; --The default value for the lowest distance is "511", represented with the signed convention.
                    i <= "00000";
                    
            -- Everytime there is a rising edge on the clock signal, the registers are updated with the values stored in the "next" signals.            
                elsif rising_edge(i_clk) then
                    
                    current_state <= next_state;
                    x <= next_x;
                    y <= next_y;
                    mask <= next_mask;
                    x_centroid <= next_x_centroid;
                    y_centroid <= next_y_centroid;
                    mask_out <= next_mask_out;
                    diff_x <= next_diff_x;
                    diff_y <= next_diff_y;
                    current_distance <= next_current_distance;
                    distance_diff <= next_distance_diff;
                    lowest_distance <= next_lowest_distance;
                    i <= next_i;
                
                end if; 
                   
        end process;
            
        --"logic" process: describes the logic of the states.
        --This process determines what must be done depending on the current state of the machine.
        
        logic: process(i_start, i_data, current_state, x, y, mask, x_centroid, y_centroid, current_distance, lowest_distance, mask_out, diff_x, diff_y, i, distance_diff) --The sensitivity list includes every signal.
        begin
        
                    --Default assignments of the "next" signals. This is done in order to preserve the values that don't change on the current state.
                    next_state <= current_state;
                    next_x <= x;
                    next_y <= y;
                    next_mask <= mask;
                    next_x_centroid <= x_centroid;
                    next_y_centroid <= y_centroid;
                    next_mask_out <= mask_out;
                    next_diff_x <= diff_x;
                    next_diff_y <= diff_y;
                    next_current_distance <= current_distance;
                    next_distance_diff <= distance_diff;
                    next_lowest_distance <= lowest_distance;
                    next_i <= i;
                    
                    --Default assignments of the output signals. Every state will overwrite them if needed.
                    --RAM output signal:
                    
                    o_address <= "0000000000000000"; -- Address of the RAM.
                    o_en <= '0'; -- Enable RAM signal.
                    o_we <= '0'; -- Set to '1' to write "o_data" at the address specified in "o_address".
                    o_data <= "00000000"; -- Data that must be written.
                    
                    --Generic output signal:
                    
                    o_done <= '0'; -- Set to '1' when the computation is over.
                      
                    --Switch-case that determines the behaviour of the FSM based on its current state.  
                    case current_state is
   
                        --IDLE state; waiting for the START signal.
                        when wait_start =>
                            if i_start = '0' then
                                next_state <= current_state;
                            elsif i_start = '1' then
                                next_state <= start;
                            end if;
                            
                        --START signal received. Sending the request for the x coordinate of the observer point.  
                        when start =>
                            o_address <= "0000000000010001"; --Address of the x coordinate of the observer point.
                            o_en <= '1';
                            o_we <= '0';
                            next_state <= x_request;
                       
                        --Waiting for the RAM to provide the data.
                        when x_request =>
                            next_state <= x_received;
                                
                        --x coordinate of the observer point received. Sending the request for the y coordinate of the observer point.
                        when x_received => 
                            next_x <= '0' & i_data; -- Adding the '0' bit to match the signed convention.
                            o_address <= "0000000000010010"; --Address of the y coordinate of the observer point.
                            o_en <= '1';
                            o_we <= '0';
                            next_state <= y_request;
                            
                        --Waiting for the RAM to provide the data.
                        when y_request =>
                            next_state <= y_received; 
                            
                        --y coordinate of the observer point received. Sending the request for the input mask.
                        when y_received =>
                            next_y <= '0' & i_data; -- Adding the '0' bit to match the signed convention.
                            o_address <= "0000000000000000";
                            o_en <= '1';
                            o_we <= '0';
                            next_state <= mask_request;
                            
                        --Waiting for the RAM to provide the data.  
                        when mask_request =>
                            next_state <= mask_received;
                            
                        --Input mask received.
                        when mask_received =>
                            next_mask <= i_data;
                            next_state <= loop_start;
                            
                        --Loop that iterates through the centroids. "i" is the index of the loop. If the i-th bit of the input mask is '1', the i-th centroid is valid and its distance from the observer point must be evaluated.
                        --NOTE: cases with "i" between 1 (00000) and 7 (00111) are not commented because their logic is the same to the one of the case with i = 0.
                        when loop_start =>
                        
                            case i is
                            
                                --If i = 8, the computation is over: every valid centroid has been analyzed. Sending the result to the RAM.
                                when "01000" =>
                                    o_en <= '1';
                                    o_we <= '1';
                                    o_data <= mask_out; --The output mask is sent to the RAM.
                                    next_state <= send_data;
                                    o_address <= "0000000000010011"; --Address 19 is where the produced output mask must be written.
                                   
                                --Step i = 0: analysing the first bit of the input mask. If it is '1', the centroid is "valid" and must be considered.
                                when "00000" =>
                                    if mask(0) = '1' then
                                        next_state <= valid_centroid; --Jumps to the sequence of states that perform the analysis of the centroid.
                                    else
                                    --If the bit is '0', the centroid must be skipped: i is incremented and the loop proceeds to the next step.
                                        next_state <= loop_start;
                                        next_i <= "00001";
                                    end if;
                                    
                                        
                                when "00001" =>
                                    if mask(1) = '1' then
                                        next_state <= valid_centroid;
                                    else
                                        next_state <= loop_start;
                                        next_i <= "00010";   
                                   end if;
                                  
                                
                                when "00010" =>
                                    if mask(2) = '1' then
                                        next_state <= valid_centroid;
                                    else
                                        next_state <= loop_start;
                                        next_i <= "00011";
                                    end if;
                                      
                                    
                                when "00011" =>
                                    if mask(3) = '1' then
                                        next_state <= valid_centroid;
                                    else
                                        next_state <= loop_start;
                                        next_i <= "00100";
                                    end if;
                                    

                                when "00100" =>
                                    if mask(4) = '1' then
                                        next_state <= valid_centroid;
                                    else
                                        next_state <= loop_start;
                                        next_i <= "00101"; 
                                    end if;
                                                  
                                    
                                when "00101" =>
                                    if mask(5) = '1' then
                                        next_state <= valid_centroid;
                                    else
                                        next_state <= loop_start;
                                        next_i <= "00110";
                                    end if;

                                      
                                when "00110" =>
                                    if mask(6) = '1' then
                                        next_state <= valid_centroid;
                                    else
                                        next_state <= loop_start;
                                        next_i <= "00111";
                                    end if;
                                    
                                    
                                when "00111" =>
                                    if mask(7) = '1' then
                                        next_state <= valid_centroid;
                                    else
                                        next_state <= loop_start;
                                        next_i <= "01000";
                                    end if;
                                    
                                    
                                --Every other invalid value of "i" causes the loop to restart.
                                when others =>
                                    next_state <= loop_start;
                                    next_i <= "00000";
                                     
                                end case;
   
   
                       -- The centroid is valid. Sending the request for the x coordinate of the centroid.
                       when valid_centroid =>
                            
                            o_address <= "00000000000" & std_logic_vector(unsigned(i) + unsigned(i) + 1); --The address of the x cooridinate is (2i + 1), extended to 16 bits. Read the documentation for a complete description of the RAM addresses.
                            o_en <= '1';
                            o_we <= '0';
                            next_state <= x_request_centroid;
                           
                       -- Waiting for the RAM to provide the data.
                       when x_request_centroid =>
                            next_state <= x_centroid_received;
                            
                       -- Sending the request for the y coordinate of the centroid.
                       when x_centroid_received =>
                            next_x_centroid <= '0' & i_data; -- Adding the '0' bit to match the signed convention.
                            o_address <= "00000000000" & std_logic_vector ( unsigned(i) + unsigned(i) + 2); --The address of the y coordinate is (2i + 2), extended to 16 bits.
                            o_en <= '1';
                            o_we <= '0';
                            next_state <= y_request_centroid;
                           
                       -- Waiting for the RAM to provide the data.
                       when y_request_centroid =>
                            next_state <= y_centroid_received;
                        
                       -- Data received from memory.  
                       when y_centroid_received =>
                            next_y_centroid <= '0' & i_data; -- Adding the '0' bit to match the signed convention.
                            next_state <= x_distance;
                            
                       -- Computing the x-distance of the observer point from the centroid. (abs(x-x0)).
                       when x_distance =>
                            next_diff_x <= std_logic_vector ( signed(x_centroid) - signed(x));
                            next_state <= check_x;
                        
                       -- The Manhattan distance requires the absolute value of the x-difference.  
                       when check_x =>
                            if diff_x(8) = '0' then
                            --If the 9-th bit of the difference is 0 (i.e diff_x is positive), we already have the absolute value of the x-distance.
                            --Let's proceed with the distance on the y axis.
                                next_state <= y_distance;
                            else
                            -- If the 9-th bit is '1', the difference is negative. We have to switch addenda and compute again the difference.
                                next_diff_x <= std_logic_vector (signed(x) - signed(x_centroid));
                                next_state <= y_distance;
                            end if;
                            
                       -- Same logic of x-distance. (abs(y-y0)).
                       when y_distance =>
                            next_diff_y <= std_logic_vector ( signed(y_centroid) - signed(y));
                            next_state <= check_y;
                        
                       -- Same logic of check_x. 
                       when check_y =>
                            if diff_y(8) = '0' then
                                next_state <= manhattan_distance;
                            else
                                next_diff_y <= std_logic_vector (signed(y) - signed(y_centroid));
                                next_state <= manhattan_distance;
                            end if;

                      -- It is now possible to compute the Manhattan distance of the centroid from the observer point.
                       when manhattan_distance =>
                            --Manhattan Distance: sqrt(abs(x - x0) + abs(y - y0))
                            next_current_distance <= '0' & std_logic_vector (unsigned(diff_x) + unsigned(diff_y)); -- Adding the '0' bit to match the signed convention.
                            next_state <= distance_difference;
 
                       -- In order to check if the current distance is lower than the lowest distance ever computed until now, we have to subtract the two values.
                       when distance_difference =>
                            next_distance_diff <= std_logic_vector (signed(current_distance) - signed(lowest_distance));
                            next_state <= check_distance;
                            
                       --Check if the current distance is lower than the lowest one, equal to it, or greater.
                       when check_distance =>
                            --If distance_diff is negative, the current centroid is the nearest one found until now.
                            if distance_diff(9) = '1' then
                                next_lowest_distance <= current_distance; --Its distance becomes the new "lowest distance".
                                next_state <= reset_mask;
                                
                            --If distance_diff is 0, the current centroid is at the same distance of the nearest one(s).
                            elsif distance_diff = "0000000000" then
                                next_state <= add_centroid;
                                
                            else
                            --If distance_diff is positive, the current centroid isn't the nearest one. The loop proceeds and analyzes the next centroid.
                                next_state <= loop_start;
                                next_i <= std_logic_vector (unsigned(i) + 1);
                            end if;
                            
                       --The current centroid is at the same distance of the nearest one(s): a '1' is added on the output mask, at the index specified by "i".    
                       when add_centroid =>
                       
                            --Just the first two cases are explained. The others follow their same logic.
                            case i is
                                --If the centroid is the first one (i=00000), the output mask will have a '1' on the first bit.
                                when "00000" =>
                                    next_mask_out <= mask_out or "00000001";
                               --If the centroid is the second one (i=00001), the output mask will have a '1' on the second bit.
                                when "00001" =>
                                    next_mask_out <= mask_out or "00000010";
                                    
                                when "00010" =>
                                    next_mask_out <= mask_out or "00000100";
                                    
                                when "00011" =>
                                    next_mask_out <= mask_out or "00001000";
                                    
                                when "00100" =>
                                    next_mask_out <= mask_out or "00010000";
                                    
                                when "00101" =>
                                    next_mask_out <= mask_out or "00100000";
                                    
                                when "00110" =>
                                    next_mask_out <= mask_out or "01000000";
                                    
                                when "00111" =>
                                    next_mask_out <= mask_out or "10000000";
                                    
                               --If "i" has an invalid value, the output mask is not altered.
                                when others =>
                                    next_mask_out <= mask_out;
                                
                                end case;
                                
                                next_state <= added_centroid;
                                     
                       --When the output mask has been edited, "i" is incremented and the loop proceeds with the analysis of the next centroid.          
                       when added_centroid =>
                            next_i <= std_logic_vector (unsigned(i) + 1);
                            next_state <= loop_start;
                                 
                            
                       --The current centroid is the nearest one: the output mask will have only a '1' at the index specified by "i".
                       when reset_mask =>
                            case i is
                             
                                --Resetting the input mask depending on the value of i.
                                when "00000" =>
                                    next_mask_out <= "00000001";
     
                                when "00001" =>
                                    next_mask_out <= "00000010";
                                    
                                when "00010" =>
                                    next_mask_out <= "00000100";
                                    
                                when "00011" =>
                                    next_mask_out <= "00001000";
                                    
                                when "00100" =>
                                    next_mask_out <= "00010000";
                                    
                                when "00101" =>
                                    next_mask_out <= "00100000";
                                    
                                when "00110" =>
                                    next_mask_out <= "01000000";
                                    
                                when "00111" =>
                                    next_mask_out <= "10000000";
                                
                                --If i has an invalid value, the mask is not altered.  
                                when others =>
                                    next_mask_out <= mask_out;
                                
                            end case;
                            
                            next_state <= added_centroid;
         
                     --Waiting for the RAM to receive the data.
                     when send_data =>
                         o_done <= '1'; --DONE signal is '1' to notify about the end of the computation.
                         next_state <= end_computation;
                         
                     --End of the computation. The machine waits for the START signal to become 0. See the documentation for the conventions about START and DONE signals.
                     when end_computation =>
                        o_done <= '1';
                        if i_start = '0' then
                            next_state <= lowered_start;
                            o_done <= '0';
                            
                        elsif i_start = '1' then
                            next_state <= current_state;
   
                        end if;
                    
                    --START signal has become 0. The machine goes back to the initial IDLE state and sets all the signals to their default values, ready to perform a new computation.    
                    when lowered_start =>
                        
                        next_state <= wait_start;
                        
                        --Setting all the signals to their default values.
                        next_x <= "000000000";
                        next_y <= "000000000";
                        next_mask <= "00000000";
                        next_x_centroid <= "000000000";
                        next_y_centroid <= "000000000";
                        next_mask_out <= "00000000";
                        next_diff_x <= "000000000";
                        next_diff_y <= "000000000";
                        next_current_distance <= "0000000000";
                        next_distance_diff <= "0000000000";
                        next_lowest_distance <= "0111111111";
                        next_i <= "00000";
                        o_address <= "0000000000000000";
                        o_en <= '0';
                        o_we <= '0';
                        o_data <= "00000000";
                        o_done <= '0';
                        
                   end case;                   
                            
        end process;

end FSM;