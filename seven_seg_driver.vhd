--=============================================================
-- seven_seg_driver.vhd
-- Basys3 4-digit seven-segment display, shows a 16-bit value
-- as 4 hex digits. Common-anode: segments and anodes active LOW.
-- Vishal Powell
--=============================================================
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity seven_seg_driver is
    port(
        clk_port  : in  std_logic;                       -- 25 MHz
        data_port : in  std_logic_vector(15 downto 0);   -- 4 hex digits to show
        seg_port  : out std_logic_vector(6 downto 0);    -- seg(0)=CA(a) .. seg(6)=CG(g), active low
        dp_port   : out std_logic;                       -- decimal point, active low
        an_port   : out std_logic_vector(3 downto 0)     -- digit anodes, active low
    );
end seven_seg_driver;

architecture behavioral of seven_seg_driver is
    signal refresh_cntr : unsigned(16 downto 0) := (others => '0');
    signal digit_sel    : std_logic_vector(1 downto 0);
    signal nibble       : std_logic_vector(3 downto 0);
begin

    -- free-running counter; top bits pick which digit is lit
    refresh_proc: process(clk_port)
    begin
        if rising_edge(clk_port) then
            refresh_cntr <= refresh_cntr + 1;
        end if;
    end process refresh_proc;

    digit_sel <= std_logic_vector(refresh_cntr(16 downto 15));  -- ~190 Hz refresh @25MHz

    -- select the active digit: drive its anode low, grab its nibble
    mux_proc: process(digit_sel, data_port)
    begin
        case digit_sel is
            when "00" =>
                an_port <= "1110";                  -- digit 0 (rightmost)
                nibble  <= data_port(3 downto 0);
            when "01" =>
                an_port <= "1101";
                nibble  <= data_port(7 downto 4);
            when "10" =>
                an_port <= "1011";
                nibble  <= data_port(11 downto 8);
            when others =>
                an_port <= "0111";                  -- digit 3 (leftmost)
                nibble  <= data_port(15 downto 12);
        end case;
    end process mux_proc;

    -- hex -> 7-seg, active low.  bit order (6..0) = g f e d c b a
    decode_proc: process(nibble)
    begin
        case nibble is
            when "0000" => seg_port <= "1000000";   -- 0
            when "0001" => seg_port <= "1111001";   -- 1
            when "0010" => seg_port <= "0100100";   -- 2
            when "0011" => seg_port <= "0110000";   -- 3
            when "0100" => seg_port <= "0011001";   -- 4
            when "0101" => seg_port <= "0010010";   -- 5
            when "0110" => seg_port <= "0000010";   -- 6
            when "0111" => seg_port <= "1111000";   -- 7
            when "1000" => seg_port <= "0000000";   -- 8
            when "1001" => seg_port <= "0010000";   -- 9
            when "1010" => seg_port <= "0001000";   -- A
            when "1011" => seg_port <= "0000011";   -- b
            when "1100" => seg_port <= "1000110";   -- C
            when "1101" => seg_port <= "0100001";   -- d
            when "1110" => seg_port <= "0000110";   -- E
            when others => seg_port <= "0001110";   -- F
        end case;
    end process decode_proc;

    dp_port <= '1';   -- decimal point off

end behavioral;
