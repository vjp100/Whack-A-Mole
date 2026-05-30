--=============================================================
-- Vishal Alisha Mazvita's Whack A Mole FSM 
-- ENGS 31 Final Project
--=============================================================

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.numeric_std.ALL;

entity whack_fsm is
Port ( 
    clk_port    : in std_logic;
    
    -- inputs
    start_pressed   : in std_logic;
    whack_pressed   : i std_logic;
    misses          : in std_logic_vector(3 downto 0);
    
    -- outputs 
    whacked         : out std_logic;
    game_on         : out std_logic;
    gameover_screen : out std_logic;
    reset           : out std_logic   
);
end whack_fsm;

architecture Behavioral of whack_fsm is

-- FSM STATES
type state_type is (
    IDLE, 
    PLAYING,
    WHACK, 
    GAME_OVER
);

signal current_state, next_state : state_type := IDLE;

begin

StateUpdate: process(clk_port)
begin
    if rising_edge(clk_port) then
        current_state <= next_state;
    end if;
end process StateUpdate;

NextStateLogic: process(current_state, whack_pressed, start_pressed, misses)
begin
    next_state <= current_state;
    
    case current_state is
        when IDLE =>
            if start_pressed = '1' then 
                next_state <= PLAYING;
            end if;
            
        when PLAYING => 
            if whack_pressed = '1' then 
                next_state <= WHACK;
            end if;
            
            if misses = "3" then    
                next_state <= GAME_OVER;
            end if;
            
        when WHACK => 
            next_state <= PLAYING;
            
        when GAME_OVER =>
            if start_pressed = '1' then
                next_state <= IDLE;
            end if;
            
        when others => null;
        
    end case;
end process NextStateLogic;

OutputLogic: process(current_state)
begin 
    whacked         <= '0';
    game_on         <= '0';
    gameover_screen <= '0';
    reset           <= '0';  
    
    case current_state is
        when IDLE => 
            reset <= '1';
        
        when PLAYING => 
            game_on <= '1';
            
        when WHACK =>
            game_on <= '1';
            whacked <= '1';
            
        when GAME_OVER => 
            gameover_screen <= '1'; 
            
        when others => null; 
        
     end case;
 end process OutputLogic;

end Behavioral;
