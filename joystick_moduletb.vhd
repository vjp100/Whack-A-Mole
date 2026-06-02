--=============================================================
-- Testbench for JoyStick (Pmod JSTK SPI receiver)
-- Vishal Powell
--
-- Models the Pmod JSTK as a SPI Mode-0 slave (data changes on the
-- SCLK falling edge, MSB first, per byte). Runs three back-to-back
-- transactions with DISTINCT data so a counter that fails to reset
-- between transactions shows up as a wrong reading on a later cycle.
--=============================================================
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity JoyStick_tb is
end JoyStick_tb;

architecture sim of JoyStick_tb is

    --------------------------------------------------------------
    -- DUT interface
    --------------------------------------------------------------
    signal clk          : std_logic := '0';
    signal take_sample  : std_logic := '0';
    signal spi_cs       : std_logic;
    signal spi_miso     : std_logic := '0';   -- driven by the Pmod model
    signal spi_sclk     : std_logic;
    signal x_axis       : std_logic_vector(9 downto 0);
    signal y_axis       : std_logic_vector(9 downto 0);
    signal buttons      : std_logic_vector(2 downto 0);
    signal right_move, left_move, up, down : std_logic;
    signal reset_button, whack_button      : std_logic;

    constant CLK_PERIOD : time := 40 ns;   -- 25 MHz

    --------------------------------------------------------------
    -- Test vectors (X 0-1023, Y 0-1023, buttons 3 bits)
    --------------------------------------------------------------
    type int_array is array (natural range <>) of integer;
    constant TEST_X   : int_array := ( 300, 1023, 512 );
    constant TEST_Y   : int_array := ( 600,    0, 511 );
    constant TEST_BTN : int_array := (   5,    2,   7 );  -- "101","010","111"

    -- Build the 40-bit packet exactly as it should land in shift_reg
    -- (byte order as sent by the Pmod, MSB of byte 1 first):
    --   [39:32] X low | [31:24] X high | [23:16] Y low | [15:8] Y high | [7:0] buttons
    function build_packet(x : integer; y : integer; btn : integer)
        return std_logic_vector is
        variable xv : std_logic_vector(9 downto 0) := std_logic_vector(to_unsigned(x, 10));
        variable yv : std_logic_vector(9 downto 0) := std_logic_vector(to_unsigned(y, 10));
        variable bv : std_logic_vector(2 downto 0) := std_logic_vector(to_unsigned(btn, 3));
        variable p  : std_logic_vector(39 downto 0);
    begin
        p(39 downto 32) := xv(7 downto 0);
        p(31 downto 24) := "000000" & xv(9 downto 8);
        p(23 downto 16) := yv(7 downto 0);
        p(15 downto  8) := "000000" & yv(9 downto 8);
        p( 7 downto  0) := "00000"  & bv;
        return p;
    end function;

    signal txn_index : integer := 0;
    signal slave_sr  : std_logic_vector(39 downto 0) := (others => '0');
    signal sim_done  : boolean := false;

begin

    --------------------------------------------------------------
    -- Clock (stops when sim_done so the sim terminates cleanly)
    --------------------------------------------------------------
    clk_gen: process
    begin
        while not sim_done loop
            clk <= '0'; wait for CLK_PERIOD/2;
            clk <= '1'; wait for CLK_PERIOD/2;
        end loop;
        wait;
    end process clk_gen;

    --------------------------------------------------------------
    -- DUT
    --------------------------------------------------------------
    dut: entity work.JoyStick
        generic map ( DELAY_COUNT => 5 )   -- short delay for fast sim
        port map (
            clk_port         => clk,
            take_sample_port => take_sample,
            spi_cs_port      => spi_cs,
            spi_s_data_port  => spi_miso,
            x_axis_port      => x_axis,
            y_axis_port      => y_axis,
            right_move       => right_move,
            left_move        => left_move,
            up               => up,
            down             => down,
            spi_sclk_port    => spi_sclk,
            button_port      => buttons,
            reset_button     => reset_button,
            whack_button     => whack_button
        );

    --------------------------------------------------------------
    -- Pmod JSTK behavioral model
    --   - loads the current packet when CS goes low
    --   - shifts to the next bit on each SCLK falling edge (Mode 0)
    --   - presents the MSB on MISO
    --------------------------------------------------------------
    pmod_model: process(spi_cs, spi_sclk)
    begin
        if falling_edge(spi_cs) then
            slave_sr <= build_packet(TEST_X(txn_index),
                                     TEST_Y(txn_index),
                                     TEST_BTN(txn_index));
        elsif falling_edge(spi_sclk) and spi_cs = '0' then
            slave_sr <= slave_sr(38 downto 0) & '0';
        end if;
    end process pmod_model;

    spi_miso <= slave_sr(39);

    --------------------------------------------------------------
    -- Stimulus + self-check
    --   Pulses take_sample once per transaction, waits for the
    --   transfer to finish (CS rises), lets PARSE settle, then
    --   compares the outputs to what was sent.
    --------------------------------------------------------------
    stim_check: process
    begin
        take_sample <= '0';
        wait for 20 * CLK_PERIOD;

        for i in TEST_X'range loop
            txn_index <= i;
            wait for CLK_PERIOD;          -- let txn_index settle before CS falls

            take_sample <= '1';
            wait for 2 us;                -- long enough to be latched in IDLE
            take_sample <= '0';

            wait until rising_edge(spi_cs);  -- 40 bits shifted, entering PARSE
            wait for 3 us;                   -- let PARSE load the output regs

            report "Txn " & integer'image(i) &
                   "  x="   & integer'image(to_integer(unsigned(x_axis))) &
                   " (exp " & integer'image(TEST_X(i)) & ")" &
                   "  y="   & integer'image(to_integer(unsigned(y_axis))) &
                   " (exp " & integer'image(TEST_Y(i)) & ")" &
                   "  btn=" & integer'image(to_integer(unsigned(buttons))) &
                   " (exp " & integer'image(TEST_BTN(i)) & ")"
                   severity note;

            assert to_integer(unsigned(x_axis)) = TEST_X(i)
                report "X MISMATCH on txn " & integer'image(i) severity error;
            assert to_integer(unsigned(y_axis)) = TEST_Y(i)
                report "Y MISMATCH on txn " & integer'image(i) severity error;
            assert to_integer(unsigned(buttons)) = TEST_BTN(i)
                report "BUTTON MISMATCH on txn " & integer'image(i) severity error;

            wait for 5 us;                -- gap before next transaction
        end loop;

        report "All transactions checked." severity note;
        sim_done <= true;
        wait;
    end process stim_check;

end sim;