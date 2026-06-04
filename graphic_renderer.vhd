library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity graphic_renderer is
    Port (
        clk         : in  std_logic;
        reset       : in  std_logic;
        game_on     : in  std_logic;
        video_on    : in  std_logic;

        mole_hole   : in  std_logic_vector(3 downto 0);
        mole_up     : in  std_logic;
        hammer_hole : in  std_logic_vector(3 downto 0);
        whacked     : in  std_logic;

        x_pixel     : in  std_logic_vector(9 downto 0);
        y_pixel     : in  std_logic_vector(9 downto 0);

        rgb_out     : out std_logic_vector(11 downto 0)
    );
end graphic_renderer;

architecture Behavioral of graphic_renderer is

    -- constants
    constant SPRITE_SIZE : integer := 160;
    constant GAME_SIZE   : integer := 480;
    constant GRID_COLS   : integer := 3;

    -- signals
    signal x_int, y_int : integer range 0 to 1023 := 0;

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

    signal in_game_area : std_logic := '0';

    -- delayed signals for 1-clock ROM latency
    signal in_game_area_d : std_logic := '0';
    signal video_on_d     : std_logic := '0';
    signal current_hole_d : integer range 0 to 8 := 0;
    signal mole_hole_d    : integer range 0 to 15 := 0;
    signal hammer_hole_d  : integer range 0 to 15 := 0;
    signal mole_up_d      : std_logic := '0';
    signal whacked_d      : std_logic := '0';
    signal game_on_d      : std_logic := '0';
    signal reset_d        : std_logic := '0';

    signal empty_rgb        : std_logic_vector(11 downto 0);
    signal mole_rgb         : std_logic_vector(11 downto 0);
    signal hammer_empty_rgb : std_logic_vector(11 downto 0);
    signal hammer_mole_rgb  : std_logic_vector(11 downto 0);
    signal whack_empty_rgb  : std_logic_vector(11 downto 0);
    signal whack_mole_rgb   : std_logic_vector(11 downto 0);
    signal grass_rgb        : std_logic_vector(11 downto 0);

    signal chosen_rgb : std_logic_vector(11 downto 0);

begin

    x_int <= to_integer(unsigned(x_pixel));
    y_int <= to_integer(unsigned(y_pixel));

    mole_hole_int   <= to_integer(unsigned(mole_hole));
    hammer_hole_int <= to_integer(unsigned(hammer_hole));

    in_game_area <= '1' when x_int < GAME_SIZE and y_int < GAME_SIZE else '0';

    grid_col <= x_int / SPRITE_SIZE when in_game_area = '1' else 0;
    grid_row <= y_int / SPRITE_SIZE when in_game_area = '1' else 0;

    current_hole <= grid_row * GRID_COLS + grid_col;

    sprite_x_int <= x_int mod SPRITE_SIZE when in_game_area = '1' else 0;
    sprite_y_int <= y_int mod SPRITE_SIZE when in_game_area = '1' else 0;

    sprite_col <= std_logic_vector(to_unsigned(sprite_x_int, 8));
    sprite_row <= std_logic_vector(to_unsigned(sprite_y_int, 8));

    sprite_col_int <= to_integer(unsigned(sprite_col));
    sprite_row_int <= to_integer(unsigned(sprite_row));

    -- delayed signals because ROM output is usually 1 clock late
    process(clk)
    begin
        if rising_edge(clk) then
            in_game_area_d <= in_game_area;
            video_on_d     <= video_on;
            current_hole_d <= current_hole;
            mole_hole_d    <= mole_hole_int;
            hammer_hole_d  <= hammer_hole_int;
            mole_up_d      <= mole_up;
            whacked_d      <= whacked;
            game_on_d      <= game_on;
            reset_d        <= reset;
        end if;
    end process;

    -- generated grass background, no ROM needed
    process(x_pixel, y_pixel)
    begin
        if x_pixel(5) = '1' and y_pixel(4) = '1' then
            grass_rgb <= x"1A2"; -- dark green
        elsif x_pixel(3) /= y_pixel(5) then
            grass_rgb <= x"2B3"; -- medium green
        else
            grass_rgb <= x"3C4"; -- light green
        end if;
    end process;

    -- sprite modules
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

    -- deciding sprite priority
    process(game_on_d, reset_d, current_hole_d, mole_hole_d, hammer_hole_d,
            mole_up_d, whacked_d, empty_rgb, mole_rgb, hammer_empty_rgb,
            hammer_mole_rgb, whack_empty_rgb, whack_mole_rgb)
    begin
        chosen_rgb <= empty_rgb;

        if reset_d = '1' then
            chosen_rgb <= empty_rgb;

        elsif game_on_d = '1' then

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

            -- 5. mole alone, only if mole_up is high
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

    -- final pixel output with transparency
    process(video_on_d, in_game_area_d, chosen_rgb, grass_rgb)
    begin
        if video_on_d = '0' then
            rgb_out <= x"000";

        elsif in_game_area_d = '1' then
            if chosen_rgb = x"000" then
                rgb_out <= grass_rgb;
            else
                rgb_out <= chosen_rgb;
            end if;

        else
            rgb_out <= x"000";
        end if;
    end process;

end Behavioral;