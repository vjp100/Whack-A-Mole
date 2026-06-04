--=============================================================
-- simple_renderer  (diagnostic dashboard build)
-- No BRAM. Combinational off pixel_x/pixel_y. Self-blanks on video_on.
--
-- LEFT 480px  : 3x3 game grid
--     brown square = mole up      red frame = hammer cell      yellow = whack
--
-- RIGHT 160px : status panel, driven by the RAW joystick signals
--     D-pad cross   -> lights cyan per direction (works even before START)
--     WHACK box     -> orange when whack button pressed
--     START box     -> blue  when start/reset button pressed
--     3 miss boxes  -> fill red as misses accumulate
--     score bar     -> grows green with score
--     panel bg      -> gray idle / green playing / red game-over
--=============================================================
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity simple_renderer is
    Port (
        clk      : in  std_logic;   -- unused (combinational); kept for compatibility
        reset    : in  std_logic;   -- unused
        video_on : in  std_logic;

        -- game state
        game_on  : in  std_logic;
        gameover : in  std_logic;

        -- mole + hammer
        mole_hole   : in  std_logic_vector(3 downto 0);
        mole_up     : in  std_logic;
        hammer_hole : in  std_logic_vector(3 downto 0);
        whacked     : in  std_logic;

        -- raw joystick signals (the thing under test)
        js_up    : in  std_logic;
        js_down  : in  std_logic;
        js_left  : in  std_logic;
        js_right : in  std_logic;
        js_whack : in  std_logic;
        js_start : in  std_logic;

        -- counters
        score  : in  std_logic_vector(7 downto 0);
        misses : in  std_logic_vector(1 downto 0);

        x_pixel : in  std_logic_vector(9 downto 0);
        y_pixel : in  std_logic_vector(9 downto 0);

        rgb_out : out std_logic_vector(11 downto 0)
    );
end simple_renderer;

architecture Behavioral of simple_renderer is
    constant CELL : integer := 160;

    -- game colors
    constant C_BLACK  : std_logic_vector(11 downto 0) := x"000";
    constant C_GRASS  : std_logic_vector(11 downto 0) := x"2A4";
    constant C_MOLE   : std_logic_vector(11 downto 0) := x"A73";
    constant C_HAMMER : std_logic_vector(11 downto 0) := x"F22";
    constant C_WHACK  : std_logic_vector(11 downto 0) := x"FF0";

    -- panel state backgrounds
    constant C_IDLE   : std_logic_vector(11 downto 0) := x"333";
    constant C_PLAY   : std_logic_vector(11 downto 0) := x"131";
    constant C_OVER   : std_logic_vector(11 downto 0) := x"411";

    -- indicator colors
    constant C_OFF    : std_logic_vector(11 downto 0) := x"555";
    constant C_DIR    : std_logic_vector(11 downto 0) := x"0FF";
    constant C_WHKON  : std_logic_vector(11 downto 0) := x"F80";
    constant C_STTON  : std_logic_vector(11 downto 0) := x"19F";
    constant C_MISSON : std_logic_vector(11 downto 0) := x"F00";
    constant C_SCORE  : std_logic_vector(11 downto 0) := x"0F0";
    constant C_CENTER : std_logic_vector(11 downto 0) := x"777";

    signal x_int, y_int : integer range 0 to 1023;
    signal score_int    : integer range 0 to 255;
    signal miss_int     : integer range 0 to 3;
begin
    x_int     <= to_integer(unsigned(x_pixel));
    y_int     <= to_integer(unsigned(y_pixel));
    score_int <= to_integer(unsigned(score));
    miss_int  <= to_integer(unsigned(misses));

    process(x_int, y_int, video_on, game_on, gameover,
            mole_hole, mole_up, hammer_hole, whacked,
            js_up, js_down, js_left, js_right, js_whack, js_start,
            score_int, miss_int)
        variable g_col, g_row, cur_hole : integer range 0 to 8;
        variable sx, sy   : integer range 0 to 159;
        variable px, py   : integer range 0 to 639;
        variable mole_h   : integer range 0 to 15;
        variable ham_h    : integer range 0 to 15;
        variable bar_w    : integer range 0 to 200;
        variable col      : std_logic_vector(11 downto 0);
    begin
        mole_h := to_integer(unsigned(mole_hole));
        ham_h  := to_integer(unsigned(hammer_hole));

        if video_on = '0' then
            col := C_BLACK;

        elsif x_int < 480 then
            -----------------------------------------------------------------
            -- GAME AREA : 3x3 grid of 160px cells
            -----------------------------------------------------------------
            g_col    := x_int / CELL;
            g_row    := y_int / CELL;
            cur_hole := g_row * 3 + g_col;
            sx       := x_int mod CELL;
            sy       := y_int mod CELL;

            col := C_GRASS;

            -- mole pops up in its cell
            if game_on = '1' and mole_up = '1' and cur_hole = mole_h and
               sx >= 40 and sx < 120 and sy >= 40 and sy < 120 then
                col := C_MOLE;
            end if;

            -- hammer drawn on top
            if game_on = '1' and cur_hole = ham_h then
                if whacked = '1' then
                    col := C_WHACK;
                elsif sx < 14 or sx >= CELL-14 or sy < 14 or sy >= CELL-14 then
                    col := C_HAMMER;
                end if;
            end if;

        else
            -----------------------------------------------------------------
            -- STATUS PANEL : x in [480,640)
            -----------------------------------------------------------------
            px := x_int - 480;   -- 0..159
            py := y_int;         -- 0..479

            -- background reflects game state
            if gameover = '1' then
                col := C_OVER;
            elsif game_on = '1' then
                col := C_PLAY;
            else
                col := C_IDLE;
            end if;

            -- D-pad cross (responds to raw joystick, no game_on gating)
            if    px >= 55 and px < 105 and py >= 10  and py < 55  then       -- UP
                if js_up = '1'    then col := C_DIR; else col := C_OFF; end if;
            elsif px >= 55 and px < 105 and py >= 105 and py < 150 then       -- DOWN
                if js_down = '1'  then col := C_DIR; else col := C_OFF; end if;
            elsif px >= 10 and px < 55  and py >= 55  and py < 105 then       -- LEFT
                if js_left = '1'  then col := C_DIR; else col := C_OFF; end if;
            elsif px >= 105 and px < 150 and py >= 55 and py < 105 then       -- RIGHT
                if js_right = '1' then col := C_DIR; else col := C_OFF; end if;
            elsif px >= 55 and px < 105 and py >= 55  and py < 105 then       -- center
                col := C_CENTER;

            -- buttons
            elsif px >= 12 and px < 76  and py >= 180 and py < 240 then       -- WHACK
                if js_whack = '1' then col := C_WHKON; else col := C_OFF; end if;
            elsif px >= 84 and px < 148 and py >= 180 and py < 240 then       -- START
                if js_start = '1' then col := C_STTON; else col := C_OFF; end if;

            -- misses (3 boxes)
            elsif py >= 280 and py < 320 and px >= 10  and px < 50  then
                if miss_int >= 1 then col := C_MISSON; else col := C_OFF; end if;
            elsif py >= 280 and py < 320 and px >= 60  and px < 100 then
                if miss_int >= 2 then col := C_MISSON; else col := C_OFF; end if;
            elsif py >= 280 and py < 320 and px >= 110 and px < 150 then
                if miss_int >= 3 then col := C_MISSON; else col := C_OFF; end if;

            -- score bar (grows rightward with score)
            elsif py >= 360 and py < 450 and px >= 10 and px < 150 then
                if score_int < 140 then bar_w := score_int; else bar_w := 140; end if;
                if (px - 10) < bar_w then
                    col := C_SCORE;
                else
                    col := C_OFF;
                end if;
            end if;
        end if;

        rgb_out <= col;
    end process;
end Behavioral;