library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use ieee.math_real.all;

library UNISIM;
use UNISIM.VComponents.all;

entity system_clock_generation is
    Port (
        input_clk_port  : in  std_logic;  -- 100 MHz input clock
        system_clk_port : out std_logic   -- 25 MHz output clock
    );
end system_clock_generation;

architecture behavioral_architecture of system_clock_generation is

    constant CLK_DIVIDER_RATIO : integer := 4;
    constant CLOCK_DIVIDER_TC  : integer := CLK_DIVIDER_RATIO / 2;

    constant COUNT_LEN : integer := integer(ceil(log2(real(CLOCK_DIVIDER_TC))));
   
    signal system_clk_divider_counter : unsigned(COUNT_LEN-1 downto 0) := (others => '0');
    signal system_clk_tog : std_logic := '0';

begin

    Clock_divider: process(input_clk_port)
    begin
        if rising_edge(input_clk_port) then
            if system_clk_divider_counter = CLOCK_DIVIDER_TC - 1 then
                system_clk_tog <= not system_clk_tog;
                system_clk_divider_counter <= (others => '0');
            else
                system_clk_divider_counter <= system_clk_divider_counter + 1;
            end if;
        end if;
    end process Clock_divider;

    Slow_clock_buffer: BUFG
        port map (
            I => system_clk_tog,
            O => system_clk_port
        );

end behavioral_architecture;