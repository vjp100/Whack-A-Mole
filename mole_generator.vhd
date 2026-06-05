--=============================================================
-- Vishal Alisha Mazvita's Whack A Mole Mole Generator Module
-- Includes:
--   - mole generation
--   - valid whack detection
--   - miss counting
--   - visible hit flash animation signal for renderer
-- ENGS 31 Final Project
--=============================================================

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity mole_generator is
    generic (
        CLK_FREQ       : integer := 25000000;
        MOLE_TIME_SEC  : integer := 2;
        HIT_FLASH_MS   : integer := 250     -- 250 ms hit animation
    );
    Port ( 
        clk         : in std_logic;
        reset       : in std_logic;
        game_on     : in std_logic;
        
        whacked     : in std_logic;
        hammer_hole : in std_logic_vector(3 downto 0);
        
        mole_hole   : out std_logic_vector(3 downto 0);
        mole_up     : out std_logic;
        valid_whack : out std_logic;
        misses      : out std_logic_vector(1 downto 0);

        -- NEW: signals for renderer hit animation
        hit_flash_active : out std_logic;
        hit_flash_hole   : out std_logic_vector(3 downto 0)
    );
end mole_generator;

architecture Behavioral of mole_generator is

    constant MOLE_TIME_COUNT : integer := CLK_FREQ * MOLE_TIME_SEC;

    -- Example:
    -- 25 MHz / 1000 = 25000 cycles per ms
    -- 25000 * 250 ms = 6,250,000 cycles = 0.25 sec
    constant HIT_FLASH_COUNT : integer := (CLK_FREQ / 1000) * HIT_FLASH_MS;

    signal timer       : integer range 0 to MOLE_TIME_COUNT := 0;
    signal mole_reg    : unsigned(3 downto 0) := "0000";
    signal mole_up_reg : std_logic := '0';

    signal valid_whack_reg : std_logic := '0';
    signal misses_reg      : unsigned(1 downto 0) := "00";

    signal lfsr         : unsigned(7 downto 0) := "10101101";
    signal prev_game_on : std_logic := '0';

    -- NEW: hit flash animation registers
    signal hit_flash_active_reg : std_logic := '0';
    signal hit_flash_hole_reg   : std_logic_vector(3 downto 0) := (others => '0');
    signal hit_flash_timer      : integer range 0 to HIT_FLASH_COUNT := 0;

    -------------------------------------------------------------------------
    -- LFSR randomizer
    -------------------------------------------------------------------------
    function next_lfsr(value : unsigned(7 downto 0)) return unsigned is
        variable feedback : std_logic;
        variable temp     : unsigned(7 downto 0);
    begin
        feedback := value(7) xor value(5) xor value(4) xor value(3);
        temp := value(6 downto 0) & feedback;

        -- LFSR should never be all zero
        if temp = "00000000" then
            temp := "10101101";
        end if;

        return temp;
    end function next_lfsr;
    
    -------------------------------------------------------------------------
    -- Convert LFSR value to hole number 0 to 8
    -------------------------------------------------------------------------
    function lfsr_to_hole(value : unsigned(7 downto 0)) return unsigned is
        variable hole_int : integer range 0 to 8;
    begin
        hole_int := to_integer(value) mod 9;
        return to_unsigned(hole_int, 4);
    end function lfsr_to_hole;
    
    -------------------------------------------------------------------------
    -- Avoid choosing the exact same hole twice in a row
    -------------------------------------------------------------------------
    function avoid_same_hole(
        new_hole : unsigned(3 downto 0);
        old_hole : unsigned(3 downto 0)
    ) return unsigned is
    begin
        if new_hole = old_hole then
            if old_hole = "1000" then
                return "0000";
            else
                return old_hole + 1;
            end if;
        else
            return new_hole;
        end if;
    end function avoid_same_hole;

begin

    process(clk, reset)
        variable rand_next : unsigned(7 downto 0);
        variable hole_next : unsigned(3 downto 0);
    begin   
        if reset = '1' then
            timer       <= 0;
            mole_reg    <= "0000";
            mole_up_reg <= '0';

            valid_whack_reg <= '0';
            misses_reg      <= "00";

            lfsr         <= "10101101";
            prev_game_on <= '0';

            hit_flash_active_reg <= '0';
            hit_flash_hole_reg   <= (others => '0');
            hit_flash_timer      <= 0;
        
        elsif rising_edge(clk) then

            -----------------------------------------------------------------
            -- valid_whack is a one-clock pulse
            -----------------------------------------------------------------
            valid_whack_reg <= '0';

            -----------------------------------------------------------------
            -- Hit flash countdown
            -- This keeps the whacked mole graphic visible long enough for VGA.
            -----------------------------------------------------------------
            if hit_flash_active_reg = '1' then
                if hit_flash_timer = 0 then
                    hit_flash_active_reg <= '0';
                else
                    hit_flash_timer <= hit_flash_timer - 1;
                end if;
            end if;

            -----------------------------------------------------------------
            -- Game off / idle
            -----------------------------------------------------------------
            if game_on = '0' then
                timer       <= 0;
                mole_up_reg <= '0';
                misses_reg  <= "00";
                prev_game_on <= '0';

                -- Optional: clear hit animation when game is not active
                hit_flash_active_reg <= '0';
                hit_flash_timer      <= 0;

            -----------------------------------------------------------------
            -- Game running
            -----------------------------------------------------------------
            else
                mole_up_reg <= '1';

                -------------------------------------------------------------
                -- Game just started, choose first mole
                -------------------------------------------------------------
                if prev_game_on = '0' then
                    rand_next := next_lfsr(lfsr);
                    lfsr <= rand_next;

                    hole_next := lfsr_to_hole(rand_next);
                    mole_reg <= avoid_same_hole(hole_next, mole_reg);

                    timer <= 0;
                    prev_game_on <= '1';

                -------------------------------------------------------------
                -- Correct whack
                -------------------------------------------------------------
                elsif whacked = '1' and unsigned(hammer_hole) = mole_reg then
                    valid_whack_reg <= '1';

                    -- NEW:
                    -- Save the hole that was hit BEFORE moving to the next mole.
                    -- This lets the renderer show the whacked mole graphic.
                    hit_flash_active_reg <= '1';
                    hit_flash_hole_reg   <= std_logic_vector(mole_reg);
                    hit_flash_timer      <= HIT_FLASH_COUNT;

                    -- Now choose the next mole
                    rand_next := next_lfsr(lfsr);
                    lfsr <= rand_next;

                    hole_next := lfsr_to_hole(rand_next);
                    mole_reg <= avoid_same_hole(hole_next, mole_reg);

                    timer <= 0;

                -------------------------------------------------------------
                -- Mole timed out, count a miss and choose new mole
                -------------------------------------------------------------
                elsif timer = MOLE_TIME_COUNT - 1 then
                    timer <= 0;

                    rand_next := next_lfsr(lfsr);
                    lfsr <= rand_next;

                    hole_next := lfsr_to_hole(rand_next);
                    mole_reg <= avoid_same_hole(hole_next, mole_reg);

                    -- Saturate at 3 misses instead of wrapping 3 back to 0
                    if misses_reg /= "11" then
                        misses_reg <= misses_reg + 1;
                    end if;

                -------------------------------------------------------------
                -- Keep current mole up
                -------------------------------------------------------------
                else
                    timer <= timer + 1;
                end if;
            end if;
        end if;
    end process;
 
    mole_hole   <= std_logic_vector(mole_reg);
    mole_up     <= mole_up_reg;
    valid_whack <= valid_whack_reg;
    misses      <= std_logic_vector(misses_reg);

    -- NEW renderer animation outputs
    hit_flash_active <= hit_flash_active_reg;
    hit_flash_hole   <= hit_flash_hole_reg;
         
end Behavioral;