library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity graphic_renderer is
    Port (
        clk         : in  std_logic;
        reset       : in  std_logic;
        game_on     : in  std_logic;
        gameover    : in  std_logic;
        video_on    : in  std_logic;

        -- mole + hammer game state
        mole_hole   : in  std_logic_vector(3 downto 0);
        mole_up     : in  std_logic;
        hammer_hole : in  std_logic_vector(3 downto 0);
        whacked     : in  std_logic;

        -- raw joystick signals for right-side diagnostic panel
        js_up       : in  std_logic;
        js_down     : in  std_logic;
        js_left     : in  std_logic;
        js_right    : in  std_logic;
        js_whack    : in  std_logic;
        js_start    : in  std_logic;

        -- counters for right-side diagnostic panel
        score       : in  std_logic_vector(7 downto 0);
        misses      : in  std_logic_vector(1 downto 0);

        -- VGA pixel position
        x_pixel     : in  std_logic_vector(9 downto 0);
        y_pixel     : in  std_logic_vector(9 downto 0);

        rgb_out     : out std_logic_vector(11 downto 0)
    );
end graphic_renderer;

architecture Behavioral of graphic_renderer is

    -------------------------------------------------------------------------
    -- Main screen layout
    -------------------------------------------------------------------------
    constant SPRITE_SIZE  : integer := 160;
    constant GAME_SIZE    : integer := 480;
    constant SCREEN_WIDTH : integer := 640;
    constant SCREEN_HEIGHT: integer := 480;
    constant GRID_COLS    : integer := 3;

    -------------------------------------------------------------------------
    -- Basic colors
    -------------------------------------------------------------------------
    constant C_BLACK  : std_logic_vector(11 downto 0) := x"000";

    -- panel state backgrounds
    constant C_IDLE   : std_logic_vector(11 downto 0) := x"333";
    constant C_PLAY   : std_logic_vector(11 downto 0) := x"131";
    constant C_OVER   : std_logic_vector(11 downto 0) := x"411";

    -- panel indicator colors
    constant C_OFF    : std_logic_vector(11 downto 0) := x"555";
    constant C_DIR    : std_logic_vector(11 downto 0) := x"0FF";
    constant C_WHKON  : std_logic_vector(11 downto 0) := x"F80";
    constant C_STTON  : std_logic_vector(11 downto 0) := x"19F";
    constant C_MISSON : std_logic_vector(11 downto 0) := x"F00";
    constant C_SCORE  : std_logic_vector(11 downto 0) := x"0F0";
    constant C_CENTER : std_logic_vector(11 downto 0) := x"777";

    -------------------------------------------------------------------------
    -- Pixel coordinate signals
    -------------------------------------------------------------------------
    signal x_int, y_int : integer range 0 to 1023 := 0;

    -- delayed coordinates to align with ROM latency
    signal x_int_d, y_int_d : integer range 0 to 1023 := 0;

    -------------------------------------------------------------------------
    -- Game grid/sprite signals
    -------------------------------------------------------------------------
    signal sprite_x_int : integer range 0 to 159 := 0;
    signal sprite_y_int : integer range 0 to 159 := 0;

    signal sprite_col : std_logic_vector(7 downto 0);
    signal sprite_row : std_logic_vector(7 downto 0);

    signal sprite_row_int : integer range 0 to 159 := 0;
    signal sprite_col_int : integer range 0 to 159 := 0;

    signal grid_row : integer range 0 to 2 := 0;
    signal grid_col : integer range 0 to 2 := 0;

    signal current_hole    : integer range 0 to 8 := 0;
    signal mole_hole_int   : integer range 0 to 15 := 0;
    signal hammer_hole_int : integer range 0 to 15 := 0;

    signal in_game_area  : std_logic := '0';
    signal in_panel_area : std_logic := '0';

    -------------------------------------------------------------------------
    -- Delayed signals for 1-clock ROM latency
    -------------------------------------------------------------------------
    signal in_game_area_d  : std_logic := '0';
    signal in_panel_area_d : std_logic := '0';
    signal video_on_d      : std_logic := '0';

    signal current_hole_d : integer range 0 to 8 := 0;
    signal mole_hole_d    : integer range 0 to 15 := 0;
    signal hammer_hole_d  : integer range 0 to 15 := 0;

    signal mole_up_d      : std_logic := '0';
    signal whacked_d      : std_logic := '0';
    signal game_on_d      : std_logic := '0';
    signal gameover_d     : std_logic := '0';
    signal reset_d        : std_logic := '0';

    signal js_up_d        : std_logic := '0';
    signal js_down_d      : std_logic := '0';
    signal js_left_d      : std_logic := '0';
    signal js_right_d     : std_logic := '0';
    signal js_whack_d     : std_logic := '0';
    signal js_start_d     : std_logic := '0';

    signal score_int      : integer range 0 to 255 := 0;
    signal score_int_d    : integer range 0 to 255 := 0;

    signal miss_int       : integer range 0 to 3 := 0;
    signal miss_int_d     : integer range 0 to 3 := 0;

    -------------------------------------------------------------------------
    -- Sprite color outputs
    -------------------------------------------------------------------------
    signal empty_rgb        : std_logic_vector(11 downto 0);
    signal mole_rgb         : std_logic_vector(11 downto 0);
    signal hammer_empty_rgb : std_logic_vector(11 downto 0);
    signal hammer_mole_rgb  : std_logic_vector(11 downto 0);
    signal whack_empty_rgb  : std_logic_vector(11 downto 0);
    signal whack_mole_rgb   : std_logic_vector(11 downto 0);

    signal grass_rgb        : std_logic_vector(11 downto 0);
    signal chosen_rgb       : std_logic_vector(11 downto 0);
    signal panel_rgb        : std_logic_vector(11 downto 0);

begin

    -------------------------------------------------------------------------
    -- Convert VGA pixel vectors into integers
    -------------------------------------------------------------------------
    x_int <= to_integer(unsigned(x_pixel));
    y_int <= to_integer(unsigned(y_pixel));

    mole_hole_int   <= to_integer(unsigned(mole_hole));
    hammer_hole_int <= to_integer(unsigned(hammer_hole));

    score_int <= to_integer(unsigned(score));
    miss_int  <= to_integer(unsigned(misses));

    -------------------------------------------------------------------------
    -- Screen area checks
    --
    -- Left 480 px: actual sprite-based 3x3 game
    -- Right 160 px: diagnostic status panel
    -------------------------------------------------------------------------
    in_game_area <= '1' when x_int < GAME_SIZE and y_int < GAME_SIZE else '0';

    in_panel_area <= '1' when x_int >= GAME_SIZE and
                              x_int < SCREEN_WIDTH and
                              y_int < SCREEN_HEIGHT
                     else '0';

    -------------------------------------------------------------------------
    -- Convert pixel position into grid cell and local sprite row/col
    -------------------------------------------------------------------------
    grid_col <= x_int / SPRITE_SIZE when in_game_area = '1' else 0;
    grid_row <= y_int / SPRITE_SIZE when in_game_area = '1' else 0;

    current_hole <= grid_row * GRID_COLS + grid_col;

    sprite_x_int <= x_int mod SPRITE_SIZE when in_game_area = '1' else 0;
    sprite_y_int <= y_int mod SPRITE_SIZE when in_game_area = '1' else 0;

    sprite_col <= std_logic_vector(to_unsigned(sprite_x_int, 8));
    sprite_row <= std_logic_vector(to_unsigned(sprite_y_int, 8));

    sprite_col_int <= to_integer(unsigned(sprite_col));
    sprite_row_int <= to_integer(unsigned(sprite_row));

    -------------------------------------------------------------------------
    -- Delay everything needed to match 1-clock sprite ROM latency
    -------------------------------------------------------------------------
    process(clk)
    begin
        if rising_edge(clk) then
            x_int_d <= x_int;
            y_int_d <= y_int;

            in_game_area_d  <= in_game_area;
            in_panel_area_d <= in_panel_area;
            video_on_d      <= video_on;

            current_hole_d <= current_hole;
            mole_hole_d    <= mole_hole_int;
            hammer_hole_d  <= hammer_hole_int;

            mole_up_d      <= mole_up;
            whacked_d      <= whacked;
            game_on_d      <= game_on;
            gameover_d     <= gameover;
            reset_d        <= reset;

            js_up_d        <= js_up;
            js_down_d      <= js_down;
            js_left_d      <= js_left;
            js_right_d     <= js_right;
            js_whack_d     <= js_whack;
            js_start_d     <= js_start;

            score_int_d    <= score_int;
            miss_int_d     <= miss_int;
        end if;
    end process;

    -------------------------------------------------------------------------
    -- Generated grass background
    -- Used whenever a sprite pixel is transparent/black.
    -------------------------------------------------------------------------
    process(x_int_d, y_int_d)
    begin
        if ((x_int_d / 32) mod 2 = 1) and ((y_int_d / 16) mod 2 = 1) then
            grass_rgb <= x"1A2"; -- dark green
        elsif ((x_int_d / 8) mod 2) /= ((y_int_d / 32) mod 2) then
            grass_rgb <= x"2B3"; -- medium green
        else
            grass_rgb <= x"3C4"; -- light green
        end if;
    end process;

    -------------------------------------------------------------------------
    -- Sprite ROM/module instances
    -------------------------------------------------------------------------
    empty_hole_inst : entity work.empty_hole_sprite
        port map (
            clk   => clk,
            row   => sprite_row_int,
            col   => sprite_col_int,
            color => empty_rgb
        );

    hole_with_mole_inst : entity work.hole_with_mole_sprite
        port map (
            clk   => clk,
            row   => sprite_row_int,
            col   => sprite_col_int,
            color => mole_rgb
        );

    hammer_inst : entity work.hammer_sprite
        port map (
            clk   => clk,
            row   => sprite_row_int,
            col   => sprite_col_int,
            color => hammer_empty_rgb
        );

    hammer_on_mole_inst : entity work.hammer_on_mole_sprite
        port map (
            clk   => clk,
            row   => sprite_row_int,
            col   => sprite_col_int,
            color => hammer_mole_rgb
        );

    hammer_whack_nothing_inst : entity work.hammer_whacking_nothing_sprite
        port map (
            clk   => clk,
            row   => sprite_row_int,
            col   => sprite_col_int,
            color => whack_empty_rgb
        );

    hammer_whack_mole_inst : entity work.hammer_whacking_mole_sprite
        port map (
            clk   => clk,
            row   => sprite_row_int,
            col   => sprite_col_int,
            color => whack_mole_rgb
        );

    -------------------------------------------------------------------------
    -- Game sprite priority logic
    --
    -- Highest priority:
    -- 1. hammer whacking mole
    -- 2. hammer whacking empty hole
    -- 3. hammer hovering over mole
    -- 4. hammer hovering over empty hole
    -- 5. mole alone
    -- 6. empty hole
    -------------------------------------------------------------------------
    process(game_on_d, gameover_d, reset_d, current_hole_d, mole_hole_d,
            hammer_hole_d, mole_up_d, whacked_d,
            empty_rgb, mole_rgb, hammer_empty_rgb,
            hammer_mole_rgb, whack_empty_rgb, whack_mole_rgb)
    begin
        chosen_rgb <= empty_rgb;

        if reset_d = '1' then
            chosen_rgb <= empty_rgb;

        elsif game_on_d = '1' and gameover_d = '0' then

            -- 1. hammer whacking mole
            if current_hole_d = hammer_hole_d and
               current_hole_d = mole_hole_d and
               mole_up_d = '1' and
               whacked_d = '1' then

                chosen_rgb <= whack_mole_rgb;

            -- 2. hammer whacking empty hole
            elsif current_hole_d = hammer_hole_d and
                  whacked_d = '1' then

                chosen_rgb <= whack_empty_rgb;

            -- 3. hammer hovering over mole
            elsif current_hole_d = hammer_hole_d and
                  current_hole_d = mole_hole_d and
                  mole_up_d = '1' then

                chosen_rgb <= hammer_mole_rgb;

            -- 4. hammer hovering over empty hole
            elsif current_hole_d = hammer_hole_d then

                chosen_rgb <= hammer_empty_rgb;

            -- 5. mole alone
            elsif current_hole_d = mole_hole_d and
                  mole_up_d = '1' then

                chosen_rgb <= mole_rgb;

            -- 6. empty hole
            else
                chosen_rgb <= empty_rgb;
            end if;

        else
            chosen_rgb <= empty_rgb;
        end if;
    end process;

    -------------------------------------------------------------------------
    -- Right-side diagnostic status panel
    --
    -- x = 480 to 639
    -- y = 0 to 479
    --
    -- This is copied from the simple renderer idea, but folded into the
    -- existing graphic_renderer instead of being a separate renderer.
    -------------------------------------------------------------------------
    process(x_int_d, y_int_d, game_on_d, gameover_d,
            js_up_d, js_down_d, js_left_d, js_right_d,
            js_whack_d, js_start_d,
            score_int_d, miss_int_d)
        variable px    : integer range 0 to 1023;
        variable py    : integer range 0 to 1023;
        variable bar_w : integer range 0 to 140;
        variable col   : std_logic_vector(11 downto 0);
    begin
        px := 0;
        py := y_int_d;
        bar_w := 0;

        if x_int_d >= GAME_SIZE then
            px := x_int_d - GAME_SIZE;
        end if;

        ---------------------------------------------------------------------
        -- Panel background: gray idle, green playing, red game-over
        ---------------------------------------------------------------------
        if gameover_d = '1' then
            col := C_OVER;
        elsif game_on_d = '1' then
            col := C_PLAY;
        else
            col := C_IDLE;
        end if;

        ---------------------------------------------------------------------
        -- D-pad cross
        -- These respond to raw joystick signals even before the game starts.
        ---------------------------------------------------------------------
        if    px >= 55 and px < 105 and py >= 10  and py < 55 then
            if js_up_d = '1' then
                col := C_DIR;
            else
                col := C_OFF;
            end if;

        elsif px >= 55 and px < 105 and py >= 105 and py < 150 then
            if js_down_d = '1' then
                col := C_DIR;
            else
                col := C_OFF;
            end if;

        elsif px >= 10 and px < 55 and py >= 55 and py < 105 then
            if js_left_d = '1' then
                col := C_DIR;
            else
                col := C_OFF;
            end if;

        elsif px >= 105 and px < 150 and py >= 55 and py < 105 then
            if js_right_d = '1' then
                col := C_DIR;
            else
                col := C_OFF;
            end if;

        elsif px >= 55 and px < 105 and py >= 55 and py < 105 then
            col := C_CENTER;

        ---------------------------------------------------------------------
        -- WHACK and START boxes
        ---------------------------------------------------------------------
        elsif px >= 12 and px < 76 and py >= 180 and py < 240 then
            if js_whack_d = '1' then
                col := C_WHKON;
            else
                col := C_OFF;
            end if;

        elsif px >= 84 and px < 148 and py >= 180 and py < 240 then
            if js_start_d = '1' then
                col := C_STTON;
            else
                col := C_OFF;
            end if;

        ---------------------------------------------------------------------
        -- Miss boxes
        ---------------------------------------------------------------------
        elsif py >= 280 and py < 320 and px >= 10 and px < 50 then
            if miss_int_d >= 1 then
                col := C_MISSON;
            else
                col := C_OFF;
            end if;

        elsif py >= 280 and py < 320 and px >= 60 and px < 100 then
            if miss_int_d >= 2 then
                col := C_MISSON;
            else
                col := C_OFF;
            end if;

        elsif py >= 280 and py < 320 and px >= 110 and px < 150 then
            if miss_int_d >= 3 then
                col := C_MISSON;
            else
                col := C_OFF;
            end if;

        ---------------------------------------------------------------------
        -- Score bar
        -- The bar maxes out at 140 pixels wide.
        ---------------------------------------------------------------------
        elsif py >= 360 and py < 450 and px >= 10 and px < 150 then
            if score_int_d < 140 then
                bar_w := score_int_d;
            else
                bar_w := 140;
            end if;

            if (px - 10) < bar_w then
                col := C_SCORE;
            else
                col := C_OFF;
            end if;
        end if;

        panel_rgb <= col;
    end process;

    -------------------------------------------------------------------------
    -- Final RGB output mux
    --
    -- Left side: sprite-based game area.
    -- Right side: diagnostic panel.
    -- Outside visible area: black.
    -------------------------------------------------------------------------
    process(video_on_d, in_game_area_d, in_panel_area_d,
            chosen_rgb, grass_rgb, panel_rgb)
    begin
        if video_on_d = '0' then
            rgb_out <= C_BLACK;

        elsif in_game_area_d = '1' then
            -- black sprite pixels are treated as transparent
            if chosen_rgb = x"000" then
                rgb_out <= grass_rgb;
            else
                rgb_out <= chosen_rgb;
            end if;

        elsif in_panel_area_d = '1' then
            rgb_out <= panel_rgb;

        else
            rgb_out <= C_BLACK;
        end if;
    end process;

end Behavioral;