----------------------------------------------------------------------
-- joystick_led_test.vhd
-- Standalone hardware sanity-check for the JoyStick module.
-- Plug this in as the top-level instead of Whack_a_mole_top_lvl
-- (same Pmod + clock pins, so your XDC needs no changes there).
--
-- LED MAP  (Basys3 LEDs light from right = LD0)
-- LD0   right_move   (X > 800)
-- LD1   left_move    (X < 212)
-- LD2   up           (Y > 800)
-- LD3   down         (Y < 212)
-- LD4   whack_button (joystick button mapped in your game)
-- LD5   reset_button (the other button)
-- LD6   -- gap --    (keeps button LEDs visually separate)
-- LD15..LD7  x_axis[9..1]  raw 9 MSBs of X (binary bar graph)
--            tilting right fills LEDs left-to-right
--            tilting left empties them
----------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.numeric_std.ALL;

entity joystick_led_test is
    port(
        clk_ext_port : in  std_logic;           -- 100 MHz board clock

        -- Pmod JSTK (same JA pin assignments as your real top-level)
        jstk_cs      : out std_logic;
        jstk_mosi    : out std_logic;
        jstk_miso    : in  std_logic;
        jstk_sclk    : out std_logic;

        -- 16 on-board LEDs (LD0..LD15)
        led          : out std_logic_vector(15 downto 0)
    );
end joystick_led_test;

architecture Behavioral of joystick_led_test is

    --------------------------------------------------------------------
    -- Components (same declarations as your real top-level)
    --------------------------------------------------------------------
    component system_clock_generator is
        generic(CLOCK_DIVIDER_RATIO : integer := 4);
        port(
            input_clk_port  : in  std_logic;
            system_clk_port : out std_logic;
            fwd_clk_port    : out std_logic
        );
    end component;

    component JoyStick is
        generic(
            N_SHIFTS    : integer := 5;
            DELAY_COUNT : integer := 375
        );
        port(
            clk_port         : in  std_logic;
            take_sample_port : in  std_logic;
            spi_cs_port      : out std_logic;
            spi_s_data_port  : in  std_logic;
            x_axis_port      : out std_logic_vector(9 downto 0);
            y_axis_port      : out std_logic_vector(9 downto 0);
            right_move       : out std_logic;
            left_move        : out std_logic;
            up               : out std_logic;
            down             : out std_logic;
            spi_sclk_port    : out std_logic;
            button_port      : out std_logic_vector(2 downto 0);
            reset_button     : out std_logic;
            whack_button     : out std_logic
        );
    end component;

    --------------------------------------------------------------------
    -- Internal signals
    --------------------------------------------------------------------
    signal system_clk    : std_logic;
    signal jstk_sclk_int : std_logic;

    signal x_axis        : std_logic_vector(9 downto 0);
    signal y_axis        : std_logic_vector(9 downto 0);  -- unused here; hook up if desired
    signal right_sig     : std_logic;
    signal left_sig      : std_logic;
    signal up_sig        : std_logic;
    signal down_sig      : std_logic;
    signal whack_sig     : std_logic;
    signal reset_sig     : std_logic;

begin

    -- 100 MHz -> 25 MHz (same ratio as your real top-level)
    sys_clk_gen : system_clock_generator
        generic map(CLOCK_DIVIDER_RATIO => 4)
        port map(
            input_clk_port  => clk_ext_port,
            system_clk_port => system_clk,
            fwd_clk_port    => open
        );

    -- Joystick: continuously sample (take_sample tied high)
    joystick_inst : JoyStick
        generic map(
            N_SHIFTS    => 5,
            DELAY_COUNT => 375
        )
        port map(
            clk_port         => system_clk,
            take_sample_port => '1',
            spi_cs_port      => jstk_cs,
            spi_s_data_port  => jstk_miso,
            x_axis_port      => x_axis,
            y_axis_port      => y_axis,
            right_move       => right_sig,
            left_move        => left_sig,
            up               => up_sig,
            down             => down_sig,
            spi_sclk_port    => jstk_sclk_int,
            button_port      => open,
            reset_button     => reset_sig,
            whack_button     => whack_sig
        );

    jstk_mosi    <= '0';           -- not sending LED commands to Pmod
    jstk_sclk    <= jstk_sclk_int;

    --------------------------------------------------------------------
    -- LED assignments
    --------------------------------------------------------------------

    -- Decoded direction flags (these are the exact signals the game uses)
    led(0) <= right_sig;
    led(1) <= left_sig;
    led(2) <= up_sig;
    led(3) <= down_sig;

    -- Button flags
    led(4) <= whack_sig;
    led(5) <= reset_sig;

    -- Gap so buttons and the bar graph are visually separated
    led(6) <= '0';

    -- Raw X axis as a 9-bit binary bar (MSB in LD15, LSB in LD7).
    -- At rest (~512 = 0b10_0000_0000) only LD15 is on.
    -- Push right toward 1023 (0b11_1111_1111) -> fills LD15..LD7.
    -- Push left toward 0   (0b00_0000_0000) -> all off.
    -- This lets you see the continuous value, not just the threshold.
    led(15 downto 7) <= (others=>'0');

end Behavioral;