--=============================================================
-- Vishal Alisha Mazvita's Whack A Mole Top Level
-- ENGS 31 Final Project
--=============================================================

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity whack_a_mole_top is
    Port (
        -- board clock
        input_clk_port : in std_logic;  -- 100 MHz clock from board

        -- buttons / joystick inputs
        start_pressed  : in std_logic;
        whack_pressed  : in std_logic;

        up             : in std_logic;
        down           : in std_logic;
        right          : in std_logic;
        left           : in std_logic;

        -- useful outputs to VGA / display modules
        hammer_hole_out     : out std_logic_vector(3 downto 0);
        mole_hole_out       : out std_logic_vector(3 downto 0);
        mole_up_out         : out std_logic;

        score_out           : out std_logic_vector(7 downto 0);
        misses_out          : out std_logic_vector(1 downto 0);

        game_on_out         : out std_logic;
        gameover_screen_out : out std_logic;
        valid_whack_out     : out std_logic;

        -- optional debug output
        reset_out           : out std_logic
    );
end whack_a_mole_top;

architecture Behavioral of whack_a_mole_top is

    -- clock signal
    signal system_clk_sig : std_logic;

    -- FSM signals
    signal game_on_sig         : std_logic;
    signal whacked_sig         : std_logic;
    signal gameover_screen_sig : std_logic;
    signal reset_sig           : std_logic;

    -- game datapath signals
    signal hammer_hole_sig : std_logic_vector(3 downto 0);
    signal mole_hole_sig   : std_logic_vector(3 downto 0);
    signal mole_up_sig     : std_logic;
    signal valid_whack_sig : std_logic;
    signal misses_sig      : std_logic_vector(1 downto 0);
    signal score_sig       : std_logic_vector(7 downto 0);

begin

    ----------------------------------------------------------------
    -- Clock Generation
    -- Converts 100 MHz board clock to 25 MHz system clock
    ----------------------------------------------------------------
    clock_gen_inst : entity work.system_clock_generation
        port map (
            input_clk_port  => input_clk_port,
            system_clk_port => system_clk_sig
        );


    ----------------------------------------------------------------
    -- FSM
    -- Controls IDLE, PLAYING, WHACK, GAME_OVER states
    ----------------------------------------------------------------
    fsm_inst : entity work.whack_fsm
        port map (
            clk_port        => system_clk_sig,

            start_pressed   => start_pressed,
            whack_pressed   => whack_pressed,
            misses          => misses_sig,

            whacked         => whacked_sig,
            game_on         => game_on_sig,
            gameover_screen => gameover_screen_sig,
            reset           => reset_sig
        );


    ----------------------------------------------------------------
    -- Hammer Movement
    -- Converts joystick movement into hammer_hole position
    ----------------------------------------------------------------
    hammer_move_inst : entity work.hammer_move
        port map (
            clk_port    => system_clk_sig,

            up          => up,
            down        => down,
            right       => right,
            left        => left,

            game_on     => game_on_sig,

            hammer_hole => hammer_hole_sig
        );


    ----------------------------------------------------------------
    -- Mole Generator
    -- Generates mole position, checks whack, counts misses
    ----------------------------------------------------------------
    mole_generator_inst : entity work.mole_generator
        generic map (
            CLK_FREQ      => 25000000,
            MOLE_TIME_SEC => 2
        )
        port map (
            clk         => system_clk_sig,
            reset       => reset_sig,
            game_on     => game_on_sig,

            whacked     => whacked_sig,
            hammer_hole => hammer_hole_sig,

            mole_hole   => mole_hole_sig,
            mole_up     => mole_up_sig,
            valid_whack => valid_whack_sig,
            misses      => misses_sig
        );


    ----------------------------------------------------------------
    -- Score Counter
    -- Increments score whenever valid_whack is high
    ----------------------------------------------------------------
    score_counter_inst : entity work.score_counter
        port map (
            clk         => system_clk_sig,
            reset       => reset_sig,
            game_on     => game_on_sig,
            valid_whack => valid_whack_sig,

            score       => score_sig
        );


    ----------------------------------------------------------------
    -- Output Assignments
    ----------------------------------------------------------------
    hammer_hole_out     <= hammer_hole_sig;
    mole_hole_out       <= mole_hole_sig;
    mole_up_out         <= mole_up_sig;

    score_out           <= score_sig;
    misses_out          <= misses_sig;

    game_on_out         <= game_on_sig;
    gameover_screen_out <= gameover_screen_sig;
    valid_whack_out     <= valid_whack_sig;

    reset_out           <= reset_sig;

end Behavioral;