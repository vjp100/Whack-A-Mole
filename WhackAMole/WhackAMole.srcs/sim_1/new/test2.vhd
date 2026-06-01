--=============================================================
-- Testbench for Mole Generator Only
--=============================================================

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity tb_mole_generator is
end tb_mole_generator;

architecture Behavioral of tb_mole_generator is

    constant CLK_PERIOD : time := 10 ns;

    signal clk         : std_logic := '0';
    signal reset       : std_logic := '0';
    signal game_on     : std_logic := '0';

    signal whacked     : std_logic := '0';
    signal hammer_hole : std_logic_vector(3 downto 0) := "0000";

    signal mole_hole   : std_logic_vector(3 downto 0);
    signal mole_up     : std_logic;
    signal valid_whack : std_logic;
    signal misses      : std_logic_vector(1 downto 0);

begin

    ------------------------------------------------------------
    -- Unit Under Test
    -- Small timer for simulation:
    -- CLK_FREQ = 5, MOLE_TIME_SEC = 1
    -- So one mole timeout = 5 clock cycles
    ------------------------------------------------------------
    uut : entity work.mole_generator
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
    -- Clock process
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
    -- Stimulus process
    ------------------------------------------------------------
    stim_process : process
    begin

        --------------------------------------------------------
        -- Test 1: Reset
        --------------------------------------------------------
        reset <= '1';
        game_on <= '0';
        whacked <= '0';
        hammer_hole <= "0000";

        wait for 25 ns;

        reset <= '0';

        wait until rising_edge(clk);
        wait for 1 ns;

        assert mole_up = '0'
            report "ERROR: mole_up should be 0 after reset"
            severity error;

        assert misses = "00"
            report "ERROR: misses should be 0 after reset"
            severity error;

        assert valid_whack = '0'
            report "ERROR: valid_whack should be 0 after reset"
            severity error;


        --------------------------------------------------------
        -- Test 2: Start game
        --------------------------------------------------------
        game_on <= '1';

        wait until rising_edge(clk);
        wait for 1 ns;

        assert mole_up = '1'
            report "ERROR: mole_up should be 1 when game_on is 1"
            severity error;

        assert unsigned(mole_hole) <= 8
            report "ERROR: mole_hole should be between 0 and 8"
            severity error;


        --------------------------------------------------------
        -- Test 3: Correct whack
        -- Put hammer on the current mole hole
        --------------------------------------------------------
        hammer_hole <= mole_hole;
        whacked <= '1';

        wait until rising_edge(clk);
        wait for 1 ns;

        assert valid_whack = '1'
            report "ERROR: valid_whack should be 1 for a correct hit"
            severity error;

        whacked <= '0';

        wait until rising_edge(clk);
        wait for 1 ns;

        assert valid_whack = '0'
            report "ERROR: valid_whack should only stay high for one clock cycle"
            severity error;


        --------------------------------------------------------
        -- Test 4: Wrong whack
        -- Hammer is placed on invalid hole 15, so it should miss
        --------------------------------------------------------
        hammer_hole <= "1111";
        whacked <= '1';

        wait until rising_edge(clk);
        wait for 1 ns;

        assert valid_whack = '0'
            report "ERROR: valid_whack should stay 0 for wrong hit"
            severity error;

        whacked <= '0';


        --------------------------------------------------------
        -- Test 5: Let mole time out once
        -- Since timeout is 5 clocks, wait 5 rising edges
        --------------------------------------------------------
        wait until rising_edge(clk);
        wait until rising_edge(clk);
        wait until rising_edge(clk);
        wait until rising_edge(clk);
        wait until rising_edge(clk);
        wait for 1 ns;

        assert misses = "01"
            report "ERROR: misses should be 1 after first timeout"
            severity error;


        --------------------------------------------------------
        -- Test 6: Let mole time out two more times
        --------------------------------------------------------
        wait until rising_edge(clk);
        wait until rising_edge(clk);
        wait until rising_edge(clk);
        wait until rising_edge(clk);
        wait until rising_edge(clk);
        wait for 1 ns;

        assert misses = "10"
            report "ERROR: misses should be 2 after second timeout"
            severity error;


        wait until rising_edge(clk);
        wait until rising_edge(clk);
        wait until rising_edge(clk);
        wait until rising_edge(clk);
        wait until rising_edge(clk);
        wait for 1 ns;

        assert misses = "11"
            report "ERROR: misses should be 3 after third timeout"
            severity error;


        --------------------------------------------------------
        -- Test 7: Make sure misses does not wrap back to 0
        --------------------------------------------------------
        wait until rising_edge(clk);
        wait until rising_edge(clk);
        wait until rising_edge(clk);
        wait until rising_edge(clk);
        wait until rising_edge(clk);
        wait for 1 ns;

        assert misses = "11"
            report "ERROR: misses should stay at 3 and not wrap to 0"
            severity error;


        --------------------------------------------------------
        -- End simulation
        --------------------------------------------------------
        report "Mole generator simulation finished successfully!";
        wait;

    end process;

end Behavioral;