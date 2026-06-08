----------------------------------------------------------------------
-- Testbench for JoyStick (Pmod JSTK SPI receiver) -- Whack-A-Mole
-- Vishal Powell / ES31-CS56
--
-- WHAT IT DOES
--   Models the Pmod JSTK as an SPI slave that streams back the standard
--   5-byte frame, then checks that the module decodes X, Y, all four
--   directions, and both buttons correctly.
--
--   Frame layout (first byte out -> last byte out), MSB-first per byte:
--     Byte1 = X[7:0]                  Byte2 = X[9:8] in the two LSBs
--     Byte3 = Y[7:0]                  Byte4 = Y[9:8] in the two LSBs
--     Byte5 = buttons in 3 LSBs (bit2 = whack, bit1 = reset, bit0 = trig)
--
--   The bit positions in make_word() are chosen to line up exactly with
--   the module's Parse_process:
--     x_axis_reg = shift_reg(25..24) & shift_reg(39..32)
--     y_axis_reg = shift_reg( 9.. 8) & shift_reg(23..16)
--     button_reg = shift_reg( 2.. 0)
----------------------------------------------------------------------
library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

entity JoyStick_tb is
end JoyStick_tb;

architecture sim of JoyStick_tb is

  -- Shrink the SS / inter-byte delay so the waveform is compact. On the
  -- board DELAY_COUNT = 375 (~15 us at 25 MHz). The exact value only
  -- changes how long CS sits idle between bytes; it does not affect the
  -- data path or the decode, so 4 is fine for simulation.
  constant TB_DELAY_COUNT : integer := 4;

  -- 25 MHz serial clock into the module (it divides by 25 -> 1 MHz SCLK)
  constant CLK_PERIOD : time := 40 ns;

  ---------------------------------------------------------------------
  -- TB <-> DUT signals
  ---------------------------------------------------------------------
  signal clk          : std_logic := '0';
  signal take_sample  : std_logic := '0';
  signal miso         : std_logic := '0';   -- we drive this (Pmod -> board)
  signal cs           : std_logic;
  signal sclk         : std_logic;
  signal x_axis       : std_logic_vector(9 downto 0);
  signal y_axis       : std_logic_vector(9 downto 0);
  signal right_move   : std_logic;
  signal left_move    : std_logic;
  signal up_move      : std_logic;
  signal down_move    : std_logic;
  signal buttons      : std_logic_vector(2 downto 0);
  signal reset_button : std_logic;
  signal whack_button : std_logic;

  -- 40-bit frame the slave model shifts out, MSB (bit 39) first
  signal spi_word     : std_logic_vector(39 downto 0) := (others => '0');

  signal sim_done     : boolean := false;

  ---------------------------------------------------------------------
  -- Build the 5-byte SPI frame from desired X, Y and button bits.
  ---------------------------------------------------------------------
  function make_word(x, y : integer;
                     b_whack, b_reset, b_trig : std_logic)
                     return std_logic_vector is
    variable w  : std_logic_vector(39 downto 0) := (others => '0');
    variable xv : std_logic_vector(9 downto 0) := std_logic_vector(to_unsigned(x, 10));
    variable yv : std_logic_vector(9 downto 0) := std_logic_vector(to_unsigned(y, 10));
  begin
    w(39 downto 32) := xv(7 downto 0);   -- Byte1  -> shift_reg(39..32)
    w(25 downto 24) := xv(9 downto 8);   -- Byte2  -> shift_reg(25..24)
    w(23 downto 16) := yv(7 downto 0);   -- Byte3  -> shift_reg(23..16)
    w( 9 downto  8) := yv(9 downto 8);   -- Byte4  -> shift_reg( 9.. 8)
    w(2) := b_whack;                     -- button_reg(2) -> whack_button
    w(1) := b_reset;                     -- button_reg(1) -> reset_button
    w(0) := b_trig;                      -- button_reg(0)
    return w;
  end function;

begin

  ---------------------------------------------------------------------
  -- 25 MHz clock
  ---------------------------------------------------------------------
  clk_gen : process
  begin
    while not sim_done loop
      clk <= '0'; wait for CLK_PERIOD/2;
      clk <= '1'; wait for CLK_PERIOD/2;
    end loop;
    wait;
  end process;

  ---------------------------------------------------------------------
  -- DUT
  ---------------------------------------------------------------------
  dut : entity work.JoyStick
    generic map (
      N_SHIFTS    => 5,
      DELAY_COUNT => TB_DELAY_COUNT
    )
    port map (
      clk_port         => clk,
      take_sample_port => take_sample,
      spi_cs_port      => cs,
      spi_s_data_port  => miso,
      x_axis_port      => x_axis,
      y_axis_port      => y_axis,
      right_move       => right_move,
      left_move        => left_move,
      up               => up_move,
      down             => down_move,
      spi_sclk_port    => sclk,
      button_port      => buttons,
      reset_button     => reset_button,
      whack_button     => whack_button
    );

  ---------------------------------------------------------------------
  -- SPI slave model (the Pmod JSTK).
  -- The module samples MISO once per SCLK period while SCLK is high. A
  -- mode-0 slave changes its data on the FALLING edge of SCLK, so the
  -- bit stays stable across the whole high phase where the module
  -- samples it. The first bit is presented when CS goes low.
  ---------------------------------------------------------------------
  spi_slave : process
    variable idx : integer;
  begin
    miso <= '0';
    wait until cs = '0';          -- start of a 5-byte frame
    idx := 39;
    miso <= spi_word(idx);        -- present MSB of byte 1
    loop
      wait until falling_edge(sclk) or cs = '1';
      exit when cs = '1';         -- frame finished (module went to PARSE)
      idx := idx - 1;
      if idx >= 0 then
        miso <= spi_word(idx);
      end if;
    end loop;
  end process;

  ---------------------------------------------------------------------
  -- Stimulus
  ---------------------------------------------------------------------
  stim : process

    procedure run_test(constant tag : in string;
                       constant x, y : in integer;
                       constant b_whack, b_reset, b_trig : in std_logic) is
      variable e_right, e_left, e_up, e_down : std_logic;
    begin
      -- expected direction decode (matches the module's thresholds)
      if x > 800 then e_right := '1'; else e_right := '0'; end if;
      if x < 212 then e_left  := '1'; else e_left  := '0'; end if;
      if y > 800 then e_up    := '1'; else e_up    := '0'; end if;
      if y < 212 then e_down  := '1'; else e_down  := '0'; end if;

      spi_word <= make_word(x, y, b_whack, b_reset, b_trig);
      wait for 200 ns;
      take_sample <= '1';
      wait until cs = '0';        -- frame started
      take_sample <= '0';         -- one frame only
      wait until cs = '1';        -- 40 bits shifted in, module in PARSE
      wait for 5 us;              -- let PARSE load the output registers

      report "[" & tag & "]  X=" & integer'image(to_integer(unsigned(x_axis))) &
             "  Y=" & integer'image(to_integer(unsigned(y_axis))) &
             "  R/L/U/D=" & std_logic'image(right_move) & std_logic'image(left_move) &
             std_logic'image(up_move) & std_logic'image(down_move) &
             "  whack=" & std_logic'image(whack_button) &
             "  reset=" & std_logic'image(reset_button);

      assert to_integer(unsigned(x_axis)) = x
        report "[" & tag & "] X readback mismatch" severity error;
      assert to_integer(unsigned(y_axis)) = y
        report "[" & tag & "] Y readback mismatch" severity error;
      assert right_move   = e_right report "[" & tag & "] right_move wrong"   severity error;
      assert left_move    = e_left  report "[" & tag & "] left_move wrong"    severity error;
      assert up_move      = e_up    report "[" & tag & "] up wrong"           severity error;
      assert down_move    = e_down  report "[" & tag & "] down wrong"         severity error;
      assert whack_button = b_whack report "[" & tag & "] whack_button wrong" severity error;
      assert reset_button = b_reset report "[" & tag & "] reset_button wrong" severity error;
    end procedure;

  begin
    wait for 1 us;

    --        tag             X     Y    whack reset trig
    run_test("center",       512,  512,  '0',  '0',  '0');
    run_test("right",       1000,  512,  '0',  '0',  '0');
    run_test("left",          20,  512,  '0',  '0',  '0');
    run_test("up",           512, 1000,  '0',  '0',  '0');
    run_test("down",         512,   20,  '0',  '0',  '0');
    run_test("up-right",    1000, 1000,  '0',  '0',  '0');
    run_test("down-left",     20,   20,  '0',  '0',  '0');
    run_test("whack btn",    512,  512,  '1',  '0',  '0');
    run_test("reset btn",    512,  512,  '0',  '1',  '0');
    run_test("right+whack", 1000,  512,  '1',  '0',  '0');

    report "All JoyStick tests finished." severity note;
    sim_done <= true;
    wait;
  end process;

end sim;