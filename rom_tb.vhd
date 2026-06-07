library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity rom_tb is
end rom_tb;

architecture Behavioral of rom_tb is

    signal clk      : std_logic := '0';
    signal rom_addr : std_logic_vector(11 downto 0) := (others => '0');
    signal rom_data : std_logic_vector(11 downto 0);
    signal ena : STD_LOGIC := '1';

begin

    --------------------------------------------------------------------
    -- Clock Generation
    --------------------------------------------------------------------
    clk <= not clk after 5 ns;

    --------------------------------------------------------------------
    -- Instantiate ROM
    --------------------------------------------------------------------
    uut : entity work.hole_with_mole
        port map (
            clka  => clk,
            addra => rom_addr,
            ena => ena,
            douta => rom_data
        );

    --------------------------------------------------------------------
    -- Test Addresses
    --------------------------------------------------------------------
    process
    begin

        -- Pixel 0
        rom_addr <= std_logic_vector(to_unsigned(0, 12));
        wait for 20 ns;

        -- Pixel 1
        rom_addr <= std_logic_vector(to_unsigned(1950, 12));
        wait for 20 ns;

        -- Pixel 2
        rom_addr <= std_logic_vector(to_unsigned(2270, 12));
        wait for 20 ns;

        -- Start of second row (64x64 image)
        rom_addr <= std_logic_vector(to_unsigned(2592, 12));
        wait for 20 ns;

        -- Row 10, Column 20
        -- Address = 10*64 + 20 = 660
        rom_addr <= std_logic_vector(to_unsigned(660, 12));
        wait for 20 ns;

        -- Row 32, Column 32
        -- Address = 32*64 + 32 = 2080
        rom_addr <= std_logic_vector(to_unsigned(2080, 12));
        wait for 20 ns;

        -- Last pixel of 64x64 image
        -- Address = 4095
        rom_addr <= std_logic_vector(to_unsigned(4095, 12));
        wait for 20 ns;

        wait;

    end process;

end Behavioral;