----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 06/02/2026 12:12:39 AM
-- Design Name: 
-- Module Name: hammer_sprite - Behavioral
-- Project Name: 
-- Target Devices: 
-- Tool Versions: 
-- Description: 
-- 
-- Dependencies: 
-- 
-- Revision:
-- Revision 0.01 - File Created
-- Additional Comments:
-- 
----------------------------------------------------------------------------------


library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity hammer_sprite is
    port (
        clk   : in  std_logic;
        row   : in  integer range 0 to 159;
        col   : in  integer range 0 to 159;
        color : out std_logic_vector(11 downto 0)
    );
end hammer_sprite;

architecture Behavioral of hammer_sprite is

    signal rom_addr : std_logic_vector(14 downto 0);
    signal rom_data : std_logic_vector(11 downto 0);
    
    component hammer_rom
    port(
        clka : IN STD_LOGIC;
    ena : IN STD_LOGIC;
    addra : IN STD_LOGIC_VECTOR(14 DOWNTO 0);
    douta : OUT STD_LOGIC_VECTOR(11 DOWNTO 0)
  );
  end component;

begin

    -- Convert row/col into ROM address
    rom_addr <= std_logic_vector(to_unsigned(row * 160 + col,15));

    -- Instantiate Block Memory Generator IP
    u_hammer_sprite : entity work.hammer_rom
        port map (
            clka  => clk,
            ena   => std_logic'('1'),
            addra => rom_addr,
            douta => rom_data
        );

    -- Output color from ROM
    color <= rom_data;


end Behavioral;
