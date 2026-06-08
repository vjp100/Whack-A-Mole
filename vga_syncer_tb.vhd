----------------------------------------------------------------------
-- Testbench for the VGA sync generator -- Whack-A-Mole / ENGS 31
-- Vishal Powell
--
-- The VGA module is self-contained: it only needs a 25 MHz clock and
-- produces HSYNC, VSYNC, video_on, pixel_x, pixel_y. So this testbench
-- IS the wrapper -- no separate top-level is needed to simulate it.
--
-- It runs ~2 full frames and measures/asserts:
--   * HSYNC period and low (retrace) width, in pixel clocks
--   * video_on active width per line, in pixel clocks
--   * VSYNC period and low (retrace) width, in lines
--
-- The expected values are TB generics. If you temporarily shrink the
-- module's constants for a faster sim (the commented "used N for sim"
-- values), just update these generics to match.
----------------------------------------------------------------------
library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

entity VGA_tb is
  generic (
    EXP_H_PERIOD   : integer := 800;  -- total pixel-clocks per line (48+640+16+96)
    EXP_H_SYNC_LOW : integer := 96;   -- HSYNC low (h_retrace) width
    EXP_H_ACTIVE   : integer := 640;  -- video_on width per active line (h_display)
    EXP_V_PERIOD   : integer := 521   -- total lines per frame (29+480+10+2)
  );
end VGA_tb;

architecture sim of VGA_tb is

  constant CLK_PERIOD : time := 40 ns;          -- 25 MHz
  constant LINE_TIME  : time := EXP_H_PERIOD * CLK_PERIOD;

  signal clk      : std_logic := '0';
  signal v_sync   : std_logic;
  signal h_sync   : std_logic;
  signal video_on : std_logic;
  signal pixel_x  : std_logic_vector(9 downto 0);
  signal pixel_y  : std_logic_vector(9 downto 0);

  signal sim_done : boolean := false;

begin

  ---------------------------------------------------------------------
  -- 25 MHz clock (this is the only stimulus the module needs)
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
  dut : entity work.VGA
    port map (
      clk      => clk,
      V_sync   => v_sync,
      H_sync   => h_sync,
      video_on => video_on,
      pixel_x  => pixel_x,
      pixel_y  => pixel_y
    );

  ---------------------------------------------------------------------
  -- HSYNC: period + low (retrace) width, measured in pixel clocks.
  -- HSYNC is active-low, so it sits high for the line and pulses low
  -- during horizontal retrace.
  ---------------------------------------------------------------------
  hsync_check : process
    variable tf1, tr, tf2 : time;
    variable low_w, period : integer;
  begin
    wait until falling_edge(h_sync);   -- skip the power-up transient
    wait until falling_edge(h_sync);
    tf1 := now;
    wait until rising_edge(h_sync);
    tr  := now;
    wait until falling_edge(h_sync);
    tf2 := now;

    low_w  := (tr  - tf1) / CLK_PERIOD;
    period := (tf2 - tf1) / CLK_PERIOD;

    report "HSYNC  : period = " & integer'image(period) &
           " clks,  low/retrace = " & integer'image(low_w) & " clks";

    assert period = EXP_H_PERIOD
      report "HSYNC period mismatch (got " & integer'image(period) & ")" severity error;
    assert low_w = EXP_H_SYNC_LOW
      report "HSYNC retrace width mismatch (got " & integer'image(low_w) & ")" severity error;
    assert low_w < period / 2
      report "HSYNC does not look active-low" severity error;
    wait;
  end process;

  ---------------------------------------------------------------------
  -- video_on: active width per line, in pixel clocks. Should equal the
  -- horizontal display region (640).
  ---------------------------------------------------------------------
  videoon_check : process
    variable t1, t2 : time;
    variable w : integer;
  begin
    wait until rising_edge(video_on);  -- first active line
    wait until falling_edge(video_on);
    wait until rising_edge(video_on);  -- measure a clean full pulse
    t1 := now;
    wait until falling_edge(video_on);
    t2 := now;

    w := (t2 - t1) / CLK_PERIOD;
    report "video_on : active width per line = " & integer'image(w) & " clks";
    assert w = EXP_H_ACTIVE
      report "video_on active width mismatch (got " & integer'image(w) & ")" severity error;
    wait;
  end process;

  ---------------------------------------------------------------------
  -- VSYNC: period + low (retrace) width, measured in LINES (divide the
  -- measured time by one line period). VSYNC is active-low and pulses
  -- low during vertical retrace.
  ---------------------------------------------------------------------
  vsync_check : process
    variable tf1, tr, tf2 : time;
    variable low_lines, period_lines : integer;
  begin
    wait until falling_edge(v_sync);   -- end of frame 1
    tf1 := now;
    wait until rising_edge(v_sync);    -- start of frame 2
    tr  := now;
    wait until falling_edge(v_sync);   -- end of frame 2
    tf2 := now;

    low_lines    := (tr  - tf1) / LINE_TIME;
    period_lines := (tf2 - tf1) / LINE_TIME;

    report "VSYNC  : period = " & integer'image(period_lines) &
           " lines,  low/retrace = " & integer'image(low_lines) & " line(s)";

    assert period_lines = EXP_V_PERIOD
      report "VSYNC period mismatch (got " & integer'image(period_lines) & ")" severity error;
    assert low_lines >= 1
      report "VSYNC never went low -- no vertical retrace pulse" severity error;

    report "All VGA timing checks complete." severity note;
    sim_done <= true;
    wait;
  end process;

end sim;