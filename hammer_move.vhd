--=============================================================
-- Vishal Alisha Mazvita's Whack A Mole Hammer Move Module
-- ENGS 31 Final Project
--=============================================================

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;


entity hammer_move is
Port ( 
    clk_port    : in std_logic;
    
    -- signals from joystick
    up    : in std_logic;
    down    : in std_logic;
    right    : in std_logic;
    left    : in std_logic;
    
    -- signal from FSM 
    game_on : in std_logic;
    
    hammer_hole : out std_logic_vector(3 downto 0)
);
end hammer_move;

architecture Behavioral of hammer_move is

signal hrow : unsigned(1 downto 0) := "00";
signal hcol : unsigned(1 downto 0) := "00";

signal prev_right : std_logic := '0';
signal prev_left  : std_logic := '0';
signal prev_up    : std_logic := '0';
signal prev_down  : std_logic := '0';

signal right_pulse : std_logic;
signal left_pulse  : std_logic;
signal up_pulse    : std_logic;
signal down_pulse  : std_logic;


begin


right_pulse <= right and not prev_right;
left_pulse  <= left  and not prev_left;
up_pulse    <= up    and not prev_up;
down_pulse  <= down  and not prev_down;

process(clk_port)
begin 
    if rising_edge(clk_port) then

        -- save previous joystick direction levels. Used for monopulsing
        prev_right <= right;
        prev_left  <= left;
        prev_up    <= up;
        prev_down  <= down;

        if game_on = '1' then

            if right_pulse = '1' and hcol < to_unsigned(2, 2) then
                hcol <= hcol + 1;
            
            elsif left_pulse = '1' and hcol > to_unsigned(0, 2) then
                hcol <= hcol - 1;
                
            elsif down_pulse = '1' and hrow < to_unsigned(2, 2) then
                hrow <= hrow + 1;
                
            elsif up_pulse = '1' and hrow > to_unsigned(0, 2) then
                hrow <= hrow - 1;
            end if;

        end if;
    end if; 
end process;

process(hrow, hcol)
    begin
        case hrow is
            when "00" =>
                case hcol is
                    when "00" => hammer_hole <= "0000"; -- hole 0
                    when "01" => hammer_hole <= "0001"; -- hole 1
                    when "10" => hammer_hole <= "0010"; -- hole 2
                    when others => hammer_hole <= "0000";
                end case;

            when "01" =>
                case hcol is
                    when "00" => hammer_hole <= "0011"; -- hole 3
                    when "01" => hammer_hole <= "0100"; -- hole 4
                    when "10" => hammer_hole <= "0101"; -- hole 5
                    when others => hammer_hole <= "0000";
                end case;

            when "10" =>
                case hcol is
                    when "00" => hammer_hole <= "0110"; -- hole 6
                    when "01" => hammer_hole <= "0111"; -- hole 7
                    when "10" => hammer_hole <= "1000"; -- hole 8
                    when others => hammer_hole <= "0000";
                end case;

            when others =>
                hammer_hole <= "0000";
        end case;
end process;

end Behavioral;
