--=============================================================
-- Vishal Alisha Mazvita's Whack A Mole Score Counter 
-- ENGS 31 Final Project
--=============================================================

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity score_counter is
    Port (
        clk         : in  std_logic;
        reset       : in  std_logic;
        game_on     : in  std_logic;
        valid_whack : in  std_logic;

        score       : out std_logic_vector(7 downto 0)
    );
end score_counter;

architecture Behavioral of score_counter is

signal score_reg : unsigned(7 downto 0) := (others => '0');

begin

    process(clk, reset)
    begin
        if reset = '1' then
            score_reg <= (others => '0');

        elsif rising_edge(clk) then
            if game_on = '0' then
                score_reg <= (others => '0');

            elsif valid_whack = '1' then
                score_reg <= score_reg + 1;
            end if;
        end if;
    end process;

    score <= std_logic_vector(score_reg);

end Behavioral;
