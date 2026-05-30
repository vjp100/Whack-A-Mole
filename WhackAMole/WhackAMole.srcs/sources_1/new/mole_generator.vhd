--=============================================================
-- Vishal Alisha Mazvita's Whack A Mole Mole Generator Module + was mole whacked?
-- ENGS 31 Final Project
--=============================================================

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity mole_generator is
    generic (
        CLK_FREQ    : integer := 25000000;
        MOLE_TIME_SEC   : integer := 2
    );
    Port ( 
        clk     : in std_logic;
        reset       : in std_logic;
        game_on     : in std_logic;
        
        
        whacked         : in std_logic;
        hammer_hole     : in std_logic_vector(3 downto 0);
        
        mole_hole   : out std_logic_vector(3 downto 0);
        mole_up     : out std_logic;
        valid_whack     : out std_logic;
        misses          : out std_logic_vector(1 downto 0)
    );
end mole_generator;

architecture Behavioral of mole_generator is

constant MOLE_TIME_COUNT    : integer := CLK_FREQ * MOLE_TIME_SEC;

signal timer        :  integer range 0 to MOLE_TIME_COUNT := 0;
signal mole_reg     : unsigned(3 downto 0) := "0000";
signal mole_up_reg  : std_logic := '0';

signal valid_whack_reg : std_logic := '0';
signal misses_reg      : unsigned(1 downto 0) := "00";

signal lfsr         : unsigned(3 downto 0) := "1011";

function lfsr_to_hole (value : in unsigned(3 downto 0)) return unsigned is 
begin 
    case value is 
        when "0000" => return "0000";
        when "0001" => return "0001";
        when "0010" => return "0010";
        when "0011" => return "0011";
        when "0100" => return "0100";
        when "0101" => return "0101";
        when "0110" => return "0110";
        when "0111" => return "0111";
        when "1000" => return "1000";
        when "1001" => return "0000";
        when "1010" => return "0001";
        when "1011" => return "0010";
        when "1100" => return "0011";
        when "1101" => return "0100";
        when "1110" => return "0101";
        when others => return "0110";
    end case;
end function lfsr_to_hole;


begin

process(clk, reset)
begin   
    if reset = '1' then
        timer       <= 0;
        mole_reg    <= "0000";
        mole_up_reg <= '0';
        lfsr        <= "1011";
        valid_whack_reg <= '0';
        misses_reg <= "00";
        
    elsif rising_edge(clk) then
        
        if game_on = '0' then   
            timer       <= 0;
            mole_up_reg <= '0';
            misses_reg <= "00";
            
        else 
           mole_up_reg <= '1';
           
           lfsr <= lfsr(2 downto 0) & (lfsr(3) xor lfsr(2));
           
           if whacked = '1' and unsigned(hammer_hole) = mole_reg then
                valid_whack_reg <= '0';
                timer <= 0;
                mole_reg <= lfsr_to_hole(lfsr);
                
           elsif timer = MOLE_TIME_COUNT - 1 then  
                timer <= 0;
                mole_reg <= lfsr_to_hole(lfsr);
                misses_reg <= misses_reg + 1;
                
           else     
                timer <= timer + 1;
           end if;
       end if;
   end if;
end process;
 
mole_hole <= std_logic_vector(mole_reg);
mole_up <= mole_up_reg;
valid_whack <= valid_whack_reg;
misses <= std_logic_vector(misses_reg);
         
end Behavioral;
