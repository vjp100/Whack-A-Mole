library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity hammer_whacking_nothing_sprite is
    port (
        clk   : in  std_logic;
        row   : in  integer range 0 to 159;
        col   : in  integer range 0 to 159;
        color : out std_logic_vector(11 downto 0)
    );
end hammer_whacking_nothing_sprite;

architecture Behavioral of hammer_whacking_nothing_sprite is

    constant C_RED         : std_logic_vector(11 downto 0) := x"F00";
    constant C_TRANSPARENT : std_logic_vector(11 downto 0) := x"000";

    constant SPRITE_MAX : integer := 159;
    constant X_THICKNESS : integer := 6;

begin

    -------------------------------------------------------------------------
    -- Generated red X sprite
    -- No ROM, no BRAM.
    -- Black pixels are treated as transparent by your renderer.
    -------------------------------------------------------------------------
    process(clk)
    begin
        if rising_edge(clk) then

            -- diagonal from top-left to bottom-right
            if abs(row - col) <= X_THICKNESS then
                color <= C_RED;

            -- diagonal from top-right to bottom-left
            elsif abs((row + col) - SPRITE_MAX) <= X_THICKNESS then
                color <= C_RED;

            -- transparent background
            else
                color <= C_TRANSPARENT;
            end if;

        end if;
    end process;

end Behavioral;