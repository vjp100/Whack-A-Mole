--=============================================================
-- Testbench for Whack A Mole FSM + Mole Generator + Score
--=============================================================

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity tb_whack_game is
end tb_whack_game;

architecture Behavioral of tb_whack_game is

    constant CLK_PERIOD : time := 10 ns;

    -- clock
    signal clk : std_logic := '0';

    -- fake button inputs
    signal start_pressed : std_logic := '0';
    signal whack_pressed : std_logic := '0';

    -- fake hammer position
    signal hammer_hole : std_logic_vector(3 downto 0) := "0000";

    -- FSM outputs
    signal whacked         : std_logic;
    signal game_on         : std_logic;
    signal gameover_screen : std_logic;
    signal reset           : std_logic;

    -- mole generator outputs
    signal mole_hole   : std_logic_vector(3 downto 0);
    signal mole_up     : std_logic;
    signal valid_whack : std_logic;
    signal misses      : std_logic_vector(1 downto 0);

    -- score output
    signal score : std_logic_vector(7 downto 0);

begin

    ------------------------------------------------------------
    -- Clock
    ------------------------------------------------------------
    clk_process : process
    begin
        while true loop
            clk <= '0';
            wait for CLK_PERIOD / 2;
            clk <= '1';
            wait for CLK_PERIOD / 2;
        end loop;
    end process;


    ------------------------------------------------------------
    -- FSM
    ------------------------------------------------------------
    fsm_inst : entity work.whack_fsm
        port map (
            clk_port        => clk,

            start_pressed   => start_pressed,
            whack_pressed   => whack_pressed,
            misses          => misses,

            whacked         => whacked,
            game_on         => game_on,
            gameover_screen => gameover_screen,
            reset           => reset
        );


    ------------------------------------------------------------
    -- Mole Generator
    -- Using a tiny mole timer for simulation:
    -- CLK_FREQ = 5 and MOLE_TIME_SEC = 1 means timeout after 5 clocks
    ------------------------------------------------------------
    mole_inst : entity work.mole_generator
        generic map (
            CLK_FREQ      => 5,
            MOLE_TIME_SEC => 1
        )
        port map (
            clk         => clk,
            reset       => reset,
            game_on     => game_on,

            whacked     => whacked,
            hammer_hole => hammer_hole,

            mole_hole   => mole_hole,
            mole_up     => mole_up,
            valid_whack => valid_whack,
            misses      => misses
        );


    ------------------------------------------------------------
    -- Score Counter
    ------------------------------------------------------------
    score_inst : entity work.score_counter
        port map (
            clk         => clk,
            reset       => reset,
            game_on     => game_on,
            valid_whack => valid_whack,

            score       => score
        );


    ------------------------------------------------------------
    -- Stimulus
    ------------------------------------------------------------
    stim_process : process
    begin

        --------------------------------------------------------
        -- Initial state should be IDLE
        --------------------------------------------------------
        wait for 20 ns;

        assert game_on = '0'
            report "ERROR: game_on should be 0 in IDLE"
            severity error;

        assert reset = '1'
            report "ERROR: reset should be 1 in IDLE"
            severity error;


        --------------------------------------------------------
        -- Press start button to enter PLAYING
        --------------------------------------------------------
        start_pressed <= '1';
        wait until rising_edge(clk);
        wait for 1 ns;
        start_pressed <= '0';

        wait until rising_edge(clk);
        wait for 1 ns;

        assert game_on = '1'
            report "ERROR: game_on should be 1 after pressing start"
            severity error;

        assert mole_up = '1'
            report "ERROR: mole_up should be 1 when game is on"
            severity error;


        --------------------------------------------------------
        -- Test a correct whack
        -- Put hammer on the current mole hole
        --------------------------------------------------------
        hammer_hole <= mole_hole;

        whack_pressed <= '1';
        wait until rising_edge(clk);
        wait for 1 ns;
        whack_pressed <= '0';

        -- FSM enters WHACK, then mole sees whacked on next clock
        wait until rising_edge(clk);
        wait for 1 ns;

        assert valid_whack = '1'
            report "ERROR: valid_whack should go high after correct whack"
            severity error;

        -- Score updates one clock after valid_whack pulse
        wait until rising_edge(clk);
        wait for 1 ns;

        assert valid_whack = '0'
            report "ERROR: valid_whack should only be high for one clock cycle"
            severity error;

        assert score = "00000001"
            report "ERROR: score should be 1 after one valid whack"
            severity error;


        --------------------------------------------------------
        -- Now do nothing and let the mole time out 3 times
        -- misses should eventually become 3, which is "11"
        --------------------------------------------------------
        wait until misses = "11";
        wait for 1 ns;

        assert misses = "11"
            report "ERROR: misses should be 3"
            severity error;


        --------------------------------------------------------
        -- FSM should see misses = 3 on the next clock
        -- and go to GAME_OVER
        --------------------------------------------------------
        wait until rising_edge(clk);
        wait for 1 ns;

        assert game_on = '0'
            report "ERROR: game_on should go low after 3 misses"
            severity error;

        assert gameover_screen = '1'
            report "ERROR: gameover_screen should be high after 3 misses"
            severity error;


        --------------------------------------------------------
        -- Make sure we are NOT pressing start in game over
        -- Game should stay over
        --------------------------------------------------------
        start_pressed <= '0';

        wait until rising_edge(clk);
        wait for 1 ns;

        assert gameover_screen = '1'
            report "ERROR: game should stay in GAME_OVER if start is not pressed"
            severity error;


        --------------------------------------------------------
        -- End simulation
        --------------------------------------------------------
        report "Simulation finished successfully!";
        wait;

    end process;

end Behavioral;