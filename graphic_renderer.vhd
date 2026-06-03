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
        hammer_hole : in  std_logic_vector(3 downto 0);
        whacked     : in  std_logic;

        x_pixel     : in  std_logic_vector(9 downto 0);
        y_pixel     : in  std_logic_vector(9 downto 0);

        rgb_out     : out std_logic_vector(11 downto 0)
    );
end graphic_renderer;

architecture Behavioral of graphic_renderer is


-- signals
    signal x_int, y_int : integer range 0 to 639 := 0;
    signal sprite_x_int : integer range 0 to 159 := 0;
    signal sprite_y_int : integer range 0 to 159 := 0;

    signal sprite_col : std_logic_vector(7 downto 0);
    signal sprite_row : std_logic_vector(7 downto 0);
    signal grass_col : std_logic_vector(8 downto 0);
    signal grass_row : std_logic_vector(8 downto 0);
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

    in_game_area <= '1' when x_int < 480 and y_int < 480 else '0';

    grid_col <= x_int / 160 when in_game_area = '1' else 0;
    grid_row <= y_int / 160 when in_game_area = '1' else 0;

    current_hole <= grid_row * 3 + grid_col;

	-- hard coding the hole numbers
    sprite_x_int <= x_int mod 160 when in_game_area = '1' else 0;
    sprite_y_int <= y_int mod 160 when in_game_area = '1' else 0;

    sprite_col <= std_logic_vector(to_unsigned(sprite_x_int, 8));
    sprite_row <= std_logic_vector(to_unsigned(sprite_y_int, 8));

    grass_col <= std_logic_vector(to_unsigned(x_int, 9)) when in_game_area = '1' else (others => '0');
    grass_row <= std_logic_vector(to_unsigned(y_int, 9)) when in_game_area = '1' else (others => '0');


-- for delayed signals because vga is annoying af
    process(clk)
    begin
        if rising_edge(clk) then
            in_game_area_d <= in_game_area;
            video_on_d     <= video_on;
            current_hole_d <= current_hole;
            mole_hole_d    <= mole_hole_int;
            hammer_hole_d  <= hammer_hole_int;
            whacked_d      <= whacked;
            game_on_d      <= game_on;
            reset_d        <= reset;
        end if;
    end process;

-- sprite moudles
    empty_hole_inst : entity work.empty_hole
        port map (
            clk   => clk,
            row   => sprite_row,
            col   => sprite_col,
            color => empty_rgb
        );

    hole_with_mole_inst : entity work.hole_with_mole_sprite
        port map (
            clk   => clk,
            row   => sprite_row,
            col   => sprite_col,
            color => mole_rgb
        );

    hammer_inst : entity work.hammer_sprite
        port map (
            clk   => clk,
            row   => sprite_row,
            col   => sprite_col,
            color => hammer_empty_rgb
        );

    hammer_on_mole_inst : entity work.hammer_on_mole_sprite
        port map (
            clk   => clk,
            row   => sprite_row,
            col   => sprite_col,
            color => hammer_mole_rgb
        );

    hammer_whack_nothing_inst : entity work.hammer_whack_nothing_sprite
        port map (
            clk   => clk,
            row   => sprite_row,
            col   => sprite_col,
            color => whack_empty_rgb
        );

    hammer_whack_mole_inst : entity work.hammer_whacking_mole_sprite
        port map (
            clk   => clk,
            row   => sprite_row,
            col   => sprite_col,
            color => whack_mole_rgb
        );

    grass_inst : entity work.grass_background
        port map (
            clk   => clk,
            row   => grass_row,
            col   => grass_col,
            color => grass_rgb
        );


-- deciding sprite priority
    process(game_on_d, reset_d, current_hole_d, mole_hole_d, hammer_hole_d, whacked_d, empty_rgb, mole_rgb, hammer_empty_rgb, hammer_mole_rgb,
            whack_empty_rgb, whack_mole_rgb)
    begin
        chosen_rgb <= empty_rgb;

        if reset_d = '1' then
            chosen_rgb <= empty_rgb;

        elsif game_on_d = '1' then

            if current_hole_d = hammer_hole_d and
               current_hole_d = mole_hole_d and
               whacked_d = '1' then

                chosen_rgb <= whack_mole_rgb;

            elsif current_hole_d = hammer_hole_d and
                  whacked_d = '1' then

                chosen_rgb <= whack_empty_rgb;

            elsif current_hole_d = hammer_hole_d and
                  current_hole_d = mole_hole_d then

                chosen_rgb <= hammer_mole_rgb;

            elsif current_hole_d = hammer_hole_d then

                chosen_rgb <= hammer_empty_rgb;

            elsif current_hole_d = mole_hole_d then

                chosen_rgb <= mole_rgb;

            else
                chosen_rgb <= empty_rgb;
            end if;

        else
            chosen_rgb <= empty_rgb;
        end if;
    end process;

-- to choose if background is being drawn at a pixel

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