library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use ieee.numeric_std.all;

entity project_reti_logiche is
    port (
        i_clk       : in    std_logic; -- Clock signal
        i_rst       : in    std_logic; -- Reset signal
        i_start     : in    std_logic; -- Start signal
        i_data      : in    std_logic_vector(7 downto 0);
        o_address   : out   std_logic_vector(15 downto 0);
        o_done      : out   std_logic;
        o_en        : out   std_logic;
        o_we        : out   std_logic;
        o_data      : out   std_logic_vector(7 downto 0)
    );
end project_reti_logiche;

architecture rtl of project_reti_logiche is
    -- Number of columns in the image
    signal n_col            : std_logic_vector(7 downto 0);
    -- Number of rows in the image
    signal n_rig            : std_logic_vector(7 downto 0);
    -- The current address the RAM has to read or write on
    signal current_address  : std_logic_vector(15 downto 0) := (others => '0');
    -- Type definition of the states in the Finite State Machine
    type state_type is (
        RESET_STATE, 
        WAIT_READ_STATE, 
        READ_STATE,
        SHIFT_COUNTER_STATE
    );
    signal current_state    : state_type := RESET_STATE;
    signal next_state       : state_type := RESET_STATE;
    -- Maximum pixel value in the original image
    signal max_pixel_value  : std_logic_vector(7 downto 0) := x"00";
    -- Minimum pixel value in the original image
    signal min_pixel_value  : std_logic_vector(7 downto 0) := x"ff";
    -- Difference between the maximum and the minimum pixel value
    signal delta_value      : std_logic_vector(7 downto 0);
    -- Number of positions to shift when computing the equalized pixel value
    -- shift_level can have values from 1 to 8 so 4 bits are necessary
    signal shift_level      : std_logic_vector(3 downto 0);
    signal pos_count        : integer := 7;
    -- Temporary pixel value after equalization
    signal temp_pixel       : std_logic_vector(7 downto 0);
    -- Equalized pixel value
    signal new_pixel_value  : std_logic_vector(7 downto 0);

begin

process (i_clk, i_rst)
begin
    if i_rst = '1' then
        current_state <= RESET_STATE;
        
    elsif rising_edge(i_clk) then
        current_state <= next_state;
        
    end if;
end process;

process (current_state, i_start, i_data, pos_count) is
    -- Count the minimum number of bits to 
    --variable pos_count      : integer := 7;
    -- Store the delta_value incremented by 1
    variable delta_plus_one : std_logic_vector(7 downto 0);

begin
    case current_state is
        -- RESET STATE: waiting for start signal
        when RESET_STATE =>
        
            -- Set values to default
            o_address <= (others => '0');
            o_done <= '0';
            o_en <= '0';
            o_we <= '0';
            o_data <= (others => '0');
            current_address <= (others => '0');
        
            -- If the start signal is received, begin computation, otherwise do nothing
            if i_start = '1' then
                -- Signal to the RAM that we want to read
                o_en <= '1';
                next_state <= WAIT_READ_STATE;
            end if;
        
        -- WAIT READ STATE: waiting for the RAM to give the requested memory contents
        when WAIT_READ_STATE =>
        
            -- Skip a cycle before reading in memory
            next_state <= READ_STATE;
        
        -- READ STATE: reading and saving contents from the RAM
        when READ_STATE =>
        
            -- Memory with address 0 contains the number of columns
            if current_address = x"0000" then
                -- Save the number of columns
                n_col <= i_data;
                
                -- Move on to the next address to read
                current_address <= current_address + 1;
                o_address <= current_address + 1;
                
                next_state <= WAIT_READ_STATE;
                    
            -- Memory with address 1 contains the number of rows 
            elsif current_address = x"0001" then
                -- Save the number of rows
                n_rig <= i_data;
                
                -- Move on to the next address to read
                current_address <= current_address + 1;
                o_address <= current_address + 1;
                
                next_state <= WAIT_READ_STATE;
                
            -- Next addresses contain the pixel values of the original image
            elsif current_address < n_col * n_rig + 2 then
                -- If a new maximum value is found, save it
                if i_data > max_pixel_value then
                    max_pixel_value <= i_data;
                end if;
                
                -- If a new minimum value if found, save it
                if i_data < min_pixel_value then
                    min_pixel_value <= i_data;
                end if;
                
                -- 0 and 255 are respectively the smallest and biggest values possible.
                -- If we have already encountered them, there's no need to keep going
                -- and the equalization process can start
                --if min_pixel_value = x"00" and max_pixel_value = x"ff" then
                --    current_address <= x"0001";
                --end if;
                
                -- Check if we've reached the last pixel or not
                if current_address < n_col * n_rig + 1 then
                    -- If we're not at the end, move on to the next address to read
                    current_address <= current_address + 1;
                    o_address <= current_address + 1;
                    
                    next_state <= WAIT_READ_STATE;
                    
                else
                    -- If we've reached the end, calculate delta_value
                    delta_value <= max_pixel_value - min_pixel_value;
                    -- Change state to calculate the shift level
                    next_state <= SHIFT_COUNTER_STATE;
                    
                end if;
                
            end if;
        
        -- SHIFT COUNTER STATE: subtract number of leading zeros from the total 
        -- number of bits in the vector delta_value + 1
        when SHIFT_COUNTER_STATE =>
            delta_plus_one := max_pixel_value - min_pixel_value + 1;
            
            if delta_plus_one(pos_count) = '0' then
                pos_count <= pos_count - 1;
                
            elsif delta_plus_one(pos_count) = '1' then
                shift_level <= std_logic_vector(TO_UNSIGNED(8 - pos_count, 4));
                
                -- Move back to the first pixel of the image
                current_address <= x"0002";
                o_address <= x"0002";
                
                -- Start reading the original bytes again to recalculate values
                next_state <= WAIT_READ_STATE;
                
            end if;
            
        -- Undefined state: do nothing
        when others =>        
    
    end case;
        
end process;

end rtl;
