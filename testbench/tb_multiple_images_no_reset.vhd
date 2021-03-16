library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.std_logic_unsigned.all;

entity project_tb is
end project_tb;

architecture projecttb of project_tb is
constant c_CLOCK_PERIOD         : time := 20 ns;
signal   tb_done                : std_logic;
signal   mem_address            : std_logic_vector (15 downto 0) := (others => '0');
signal   tb_rst                 : std_logic := '0';
signal   tb_start               : std_logic := '0';
signal   tb_clk                 : std_logic := '0';
signal   mem_o_data,mem_i_data  : std_logic_vector (7 downto 0);
signal   enable_wire            : std_logic;
signal   mem_we                 : std_logic;

type ram_type is array (65535 downto 0) of std_logic_vector(7 downto 0);
----------------------------------
-- Immagine originale = [ 46, 131]
--                      [ 62,  89]  
-- Immagine di output = [  0, 255]
--                      [ 64, 172]
----------------------------------  
signal RAM: ram_type := (0 => std_logic_vector(to_unsigned( 2   , 8)), 
                         1 => std_logic_vector(to_unsigned( 2   , 8)), 
                         2 => std_logic_vector(to_unsigned( 46  , 8)),  
                         3 => std_logic_vector(to_unsigned( 131 , 8)), 
                         4 => std_logic_vector(to_unsigned( 62  , 8)), 
                         5 => std_logic_vector(to_unsigned( 89  , 8)),
                         others => (others =>'0'));

-- When true it signals that the new image should be loaded into the RAM
signal  change_image : boolean := false;

component project_reti_logiche is
port (
      i_clk         : in  std_logic;
      i_rst         : in  std_logic;
      i_start       : in  std_logic;
      i_data        : in  std_logic_vector(7 downto 0);
      o_address     : out std_logic_vector(15 downto 0);
      o_done        : out std_logic;
      o_en          : out std_logic;
      o_we          : out std_logic;
      o_data        : out std_logic_vector (7 downto 0)
      );
end component project_reti_logiche;


begin
UUT: project_reti_logiche
port map (
          i_clk      	=> tb_clk,
          i_rst      	=> tb_rst,
          i_start       => tb_start,
          i_data    	=> mem_o_data,
          o_address  	=> mem_address,
          o_done      	=> tb_done,
          o_en   	    => enable_wire,
          o_we 		    => mem_we,
          o_data    	=> mem_i_data
          );

p_CLK_GEN : process is
begin
    wait for c_CLOCK_PERIOD/2;
    tb_clk <= not tb_clk;
end process p_CLK_GEN;


MEM : process(tb_clk)
begin
    if tb_clk'event and tb_clk = '1' then
        if change_image then
            -----------------------------------------
            -- Immagine nuova =  [138, 204,  64,  64]
            --                   [204,  64,  89,  64]
            --                   [64 , 138,  89, 138]
            --                   [138, 204, 204,  64]
            -----------------------------------------
            -- Immagine output = [148, 255,   0,   0]
            --                   [255,   0,  50,   0]
            --                   [  0, 148,  50, 148]
            --                   [148, 255, 255,   0]
            -----------------------------------------
            RAM <= ( 0  => std_logic_vector(to_unsigned(  4    , 8)), 
                     1  => std_logic_vector(to_unsigned(  4    , 8)), 
                     2  => std_logic_vector(to_unsigned(  138  , 8)),  
                     3  => std_logic_vector(to_unsigned(  204  , 8)), 
                     4  => std_logic_vector(to_unsigned(  64   , 8)), 
                     5  => std_logic_vector(to_unsigned(  64   , 8)),
                     6  => std_logic_vector(to_unsigned(  204  , 8)),  
                     7  => std_logic_vector(to_unsigned(  64   , 8)), 
                     8  => std_logic_vector(to_unsigned(  89   , 8)), 
                     9  => std_logic_vector(to_unsigned(  64   , 8)),
                     10 => std_logic_vector(to_unsigned(  64   , 8)),  
                     11 => std_logic_vector(to_unsigned(  138  , 8)), 
                     12 => std_logic_vector(to_unsigned(  89   , 8)), 
                     13 => std_logic_vector(to_unsigned(  138  , 8)),
                     14 => std_logic_vector(to_unsigned(  138  , 8)),  
                     15 => std_logic_vector(to_unsigned(  204  , 8)), 
                     16 => std_logic_vector(to_unsigned(  204  , 8)), 
                     17 => std_logic_vector(to_unsigned(  64   , 8)),
                     others => (others =>'0'));
                     
        elsif enable_wire = '1' then
            if mem_we = '1' then
                RAM(conv_integer(mem_address))  <= mem_i_data;
                mem_o_data                      <= mem_i_data after 1 ns;
            else
                mem_o_data <= RAM(conv_integer(mem_address)) after 1 ns;
            end if;
        end if;
    end if;
end process;

test : process is
begin 
    wait for 50 ns;
    wait for c_CLOCK_PERIOD;
    tb_rst <= '1';
    wait for c_CLOCK_PERIOD;
    wait for 50 ns;
    tb_rst <= '0';
    wait for c_CLOCK_PERIOD;
    wait for 50 ns;
    tb_start <= '1';
    wait for c_CLOCK_PERIOD;
    wait until tb_done = '1';
    wait for c_CLOCK_PERIOD;
    tb_start <= '0';
    wait until tb_done = '0';
    wait for 50ns;
    
    assert RAM(6) = std_logic_vector(to_unsigned( 0   , 8)) report "TEST FALLITO (WORKING ZONE). Expected 0   found " & integer'image(to_integer(unsigned(RAM(6)))) severity failure;
    assert RAM(7) = std_logic_vector(to_unsigned( 255 , 8)) report "TEST FALLITO (WORKING ZONE). Expected 255 found " & integer'image(to_integer(unsigned(RAM(7)))) severity failure;
    assert RAM(8) = std_logic_vector(to_unsigned( 64  , 8)) report "TEST FALLITO (WORKING ZONE). Expected 64  found " & integer'image(to_integer(unsigned(RAM(8)))) severity failure;
    assert RAM(9) = std_logic_vector(to_unsigned( 172 , 8)) report "TEST FALLITO (WORKING ZONE). Expected 172 found " & integer'image(to_integer(unsigned(RAM(9)))) severity failure;
    
    -- Load new image into RAM
    change_image <= true;
    wait for c_CLOCK_PERIOD;
    change_image <= false;
    wait for c_CLOCK_PERIOD;
    
    wait for 50 ns;
    tb_start <= '1';
    wait for c_CLOCK_PERIOD;
    wait until tb_done = '1';
    wait for c_CLOCK_PERIOD;
    tb_start <= '0';
    wait until tb_done = '0';
    wait for 50 ns;
    
    assert RAM(18) = std_logic_vector(to_unsigned( 148 , 8)) report "TEST FALLITO (WORKING ZONE). Expected  148 found " & integer'image(to_integer(unsigned(RAM(18))))  severity failure;
    assert RAM(19) = std_logic_vector(to_unsigned( 255 , 8)) report "TEST FALLITO (WORKING ZONE). Expected  255 found " & integer'image(to_integer(unsigned(RAM(19))))  severity failure;
    assert RAM(20) = std_logic_vector(to_unsigned( 0   , 8)) report "TEST FALLITO (WORKING ZONE). Expected  0   found " & integer'image(to_integer(unsigned(RAM(20))))  severity failure;
    assert RAM(21) = std_logic_vector(to_unsigned( 0   , 8)) report "TEST FALLITO (WORKING ZONE). Expected  0   found " & integer'image(to_integer(unsigned(RAM(21))))  severity failure;
    assert RAM(22) = std_logic_vector(to_unsigned( 255 , 8)) report "TEST FALLITO (WORKING ZONE). Expected  255 found " & integer'image(to_integer(unsigned(RAM(22))))  severity failure;
    assert RAM(23) = std_logic_vector(to_unsigned( 0   , 8)) report "TEST FALLITO (WORKING ZONE). Expected  0   found " & integer'image(to_integer(unsigned(RAM(23))))  severity failure;
    assert RAM(24) = std_logic_vector(to_unsigned( 50  , 8)) report "TEST FALLITO (WORKING ZONE). Expected  50  found " & integer'image(to_integer(unsigned(RAM(24))))  severity failure;
    assert RAM(25) = std_logic_vector(to_unsigned( 0   , 8)) report "TEST FALLITO (WORKING ZONE). Expected  0   found " & integer'image(to_integer(unsigned(RAM(25))))  severity failure;
    assert RAM(26) = std_logic_vector(to_unsigned( 0   , 8)) report "TEST FALLITO (WORKING ZONE). Expected  0   found " & integer'image(to_integer(unsigned(RAM(26))))  severity failure;
    assert RAM(27) = std_logic_vector(to_unsigned( 148 , 8)) report "TEST FALLITO (WORKING ZONE). Expected  148 found " & integer'image(to_integer(unsigned(RAM(27))))  severity failure;
    assert RAM(28) = std_logic_vector(to_unsigned( 50  , 8)) report "TEST FALLITO (WORKING ZONE). Expected  50  found " & integer'image(to_integer(unsigned(RAM(28))))  severity failure;
    assert RAM(29) = std_logic_vector(to_unsigned( 148 , 8)) report "TEST FALLITO (WORKING ZONE). Expected  148 found " & integer'image(to_integer(unsigned(RAM(29))))  severity failure;
    assert RAM(30) = std_logic_vector(to_unsigned( 148 , 8)) report "TEST FALLITO (WORKING ZONE). Expected  148 found " & integer'image(to_integer(unsigned(RAM(30))))  severity failure;
    assert RAM(31) = std_logic_vector(to_unsigned( 255 , 8)) report "TEST FALLITO (WORKING ZONE). Expected  255 found " & integer'image(to_integer(unsigned(RAM(31))))  severity failure;
    assert RAM(32) = std_logic_vector(to_unsigned( 255 , 8)) report "TEST FALLITO (WORKING ZONE). Expected  255 found " & integer'image(to_integer(unsigned(RAM(32))))  severity failure;
    assert RAM(33) = std_logic_vector(to_unsigned( 0   , 8)) report "TEST FALLITO (WORKING ZONE). Expected  0   found " & integer'image(to_integer(unsigned(RAM(33))))  severity failure;

    assert false report "Simulation Ended! TEST PASSATO" severity failure;
end process test;

end projecttb;