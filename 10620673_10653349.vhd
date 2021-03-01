library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use ieee.std_logic_unsigned.all;
use ieee.numeric_std.all;

entity project_reti_logiche is
    port (
        i_clk       : in    std_logic;
        i_rst       : in    std_logic;
        i_start     : in    std_logic;
        i_data      : in    std_logic_vector(7 downto 0);
        o_address   : out   std_logic_vector(15 downto 0);
        o_done      : out   std_logic;
        o_en        : out   std_logic;
        o_we        : out   std_logic;
        o_data      : out   std_logic_vector(7 downto 0)
    );
end project_reti_logiche;

architecture rtl of project_reti_logiche is

    signal n_col            : std_logic_vector(7 downto 0);
    signal n_rig            : std_logic_vector(7 downto 0);
    signal current_address  : std_logic_vector(15 downto 0) := (others => '0');
    
    type state_type is (reset_state, wait_read_state, read_state);
    signal current_state    : state_type := reset_state;
    
    signal max_pixel_value  : std_logic_vector(7 downto 0);
    signal min_pixel_value  : std_logic_vector(7 downto 0);
    signal delta_value      : std_logic_vector(7 downto 0);
    signal shift_level      : std_logic_vector(7 downto 0);
    signal temp_pixel       : std_logic_vector(7 downto 0);
    signal new_pixel_value  : std_logic_vector(7 downto 0);

begin

process (i_clk) is
begin
    if rising_edge(i_clk) then
        -- Reset the module
        if i_rst = '1' then
            -- Set values to default
            o_address <= (others => '0');
            o_done <= '0';
            o_en <= '0';
            o_we <= '0';
            o_data <= (others => '0');
            current_address <= (others => '0');
            -- Move to reset state
            current_state <= reset_state;
            
        -- Not resetting
        else
        
            case current_state is
            
                when reset_state =>
                    -- Receive start signal
                    if i_start = '1' then
                        -- Signal to the RAM that we want to read
                        o_en <= '1';
                        current_state <= wait_read_state;
                    end if;
                
                when wait_read_state =>
                    
                    case current_address is 
                    
                        when std_logic_vector(to_unsigned(0, 16)) =>
                            n_col <= i_data;
                        
                        when std_logic_vector(TO_UNSIGNED(1, 16)) =>
                            n_rig <= i_data;
                        
                        when others =>  
                    
                    end case;
                    
                    current_address <= current_address + 1;
                    o_address <= current_address;
                
                when others =>        
            
            end case;
        
        end if;
    
    end if;
end process;

end rtl;
