library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity hole_with_mole_sprite is
    port (
        clk   : in  std_logic;
        row   : in  integer range 0 to 159;
        col   : in  integer range 0 to 159;
        color : out std_logic_vector(11 downto 0)
    );
end hole_with_mole_sprite;

architecture Behavioral of hole_with_mole_sprite is

    signal rom_addr : std_logic_vector(14 downto 0);
    signal rom_data : std_logic_vector(11 downto 0);
    
      component hole_with_mole_rom
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
    u_hole_with_mole_sprite : entity work.hole_with_mole_rom
        port map (
            clka  => clk,
            ena   => std_logic'('1'),
            addra => rom_addr,
            douta => rom_data
        );

    -- Output color from ROM
    color <= rom_data;

end Behavioral;