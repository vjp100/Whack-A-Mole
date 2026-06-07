--=============================================================
-- Vishal Alisha Mazvita's Whack A Mole FSM 
-- ENGS 31 Final Project
--
-- Updated:
--   - GAME_OVER lasts about 1 second
--   - then FSM goes to RESET_GAME for 1 clock
--   - then FSM goes to IDLE
--   - IDLE does NOT hold reset high, so start screen can display
--=============================================================

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity whack_fsm is
Port ( 
    clk_port    : in std_logic;
    
    -- inputs
    start_pressed   : in std_logic;
    whack_pressed   : in std_logic;
    misses          : in std_logic_vector(1 downto 0);
    
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
        GAME_OVER,
        RESET_GAME
    );

    signal current_state, next_state : state_type := IDLE;

    -- 25 MHz clock:
    -- 25,000,000 cycles = 1 second
    constant GAMEOVER_TIME_COUNT : integer := 25000000;

    signal gameover_timer : integer range 0 to GAMEOVER_TIME_COUNT := 0;

begin

    -------------------------------------------------------------------------
    -- State register + gameover timer
    -------------------------------------------------------------------------
    StateUpdate: process(clk_port)
    begin
        if rising_edge(clk_port) then
            current_state <= next_state;

            -- Count only while currently in GAME_OVER
            if current_state = GAME_OVER then
                if gameover_timer = GAMEOVER_TIME_COUNT - 1 then
                    gameover_timer <= 0;
                else
                    gameover_timer <= gameover_timer + 1;
                end if;
            else
                gameover_timer <= 0;
            end if;
        end if;
    end process StateUpdate;

    -------------------------------------------------------------------------
    -- Next state logic
    -------------------------------------------------------------------------
    NextStateLogic: process(current_state, whack_pressed, start_pressed, misses, gameover_timer)
    begin
        next_state <= current_state;
        
        case current_state is

            -----------------------------------------------------------------
            -- Start screen state
            -- game_on = 0, gameover_screen = 0, reset = 0
            -----------------------------------------------------------------
            when IDLE =>
                if start_pressed = '1' then 
                    next_state <= PLAYING;
                else
                    next_state <= IDLE;
                end if;
                
            -----------------------------------------------------------------
            -- Main gameplay state
            -----------------------------------------------------------------
            when PLAYING => 
                if misses = "11" then    
                    next_state <= GAME_OVER;

                elsif whack_pressed = '1' then 
                    next_state <= WHACK;

                else
                    next_state <= PLAYING;
                end if;
                
            -----------------------------------------------------------------
            -- One-clock whack pulse state
            -----------------------------------------------------------------
            when WHACK => 
                next_state <= PLAYING;
                
            -----------------------------------------------------------------
            -- Game over screen stays for about 1 second
            -----------------------------------------------------------------
            when GAME_OVER =>
                if gameover_timer = GAMEOVER_TIME_COUNT - 1 then
                    next_state <= RESET_GAME;
                else
                    next_state <= GAME_OVER;
                end if;

            -----------------------------------------------------------------
            -- One-clock reset pulse after gameover
            -- This clears datapath/mole/misses/etc.
            -- Then IDLE can show the start screen.
            -----------------------------------------------------------------
            when RESET_GAME =>
                next_state <= IDLE;
                
            when others =>
                next_state <= IDLE;
            
        end case;
    end process NextStateLogic;

    -------------------------------------------------------------------------
    -- Output logic
    -------------------------------------------------------------------------
    OutputLogic: process(current_state)
    begin 
        -- defaults
        whacked         <= '0';
        game_on         <= '0';
        gameover_screen <= '0';
        reset           <= '0';  
        
        case current_state is

            -----------------------------------------------------------------
            -- IDLE means show start screen.
            -- IMPORTANT: reset is NOT high here.
            -----------------------------------------------------------------
            when IDLE => 
                whacked         <= '0';
                game_on         <= '0';
                gameover_screen <= '0';
                reset           <= '0';

            -----------------------------------------------------------------
            -- Gameplay
            -----------------------------------------------------------------
            when PLAYING => 
                game_on <= '1';

            -----------------------------------------------------------------
            -- Whack pulse
            -----------------------------------------------------------------
            when WHACK =>
                game_on <= '1';
                whacked <= '1';

            -----------------------------------------------------------------
            -- Gameover screen
            -----------------------------------------------------------------
            when GAME_OVER => 
                game_on         <= '0';
                gameover_screen <= '1'; 
                reset           <= '0';

            -----------------------------------------------------------------
            -- One-clock reset pulse
            -----------------------------------------------------------------
            when RESET_GAME =>
                game_on         <= '0';
                gameover_screen <= '0';
                reset           <= '1';

            when others =>
                whacked         <= '0';
                game_on         <= '0';
                gameover_screen <= '0';
                reset           <= '0';
        
        end case;
    end process OutputLogic;

end Behavioral;