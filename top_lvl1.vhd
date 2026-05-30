library IEEE;
use IEEE.std_logic_1164.all;

entity vga_top is
    port(
        clk            : in  std_logic;
        rst            : in  std_logic;
        pattern_select : in  std_logic;  -- 0 = vga_test_pattern, 1 = vga_test_pattern_12bit
        hsync          : out std_logic;
        vsync          : out std_logic;
        red            : out std_logic_vector(3 downto 0);
        green          : out std_logic_vector(3 downto 0);
        blue           : out std_logic_vector(3 downto 0)
    );
end entity vga_top;

architecture rtl of vga_top is
    component VGA_SYNCer is
        port(
            clk    : in  std_logic;
            rst    : in  std_logic;
            hsync  : out std_logic;
            vsync  : out std_logic;
            active : out std_logic;
            hcount : out std_logic_vector(10 downto 0);
            vcount : out std_logic_vector(9 downto 0)
        );
    end component;

    component vga_test_pattern is
        port(
            clk    : in  std_logic;
            active : in  std_logic;
            hcount : in  std_logic_vector(10 downto 0);
            vcount : in  std_logic_vector(9 downto 0);
            red    : out std_logic_vector(3 downto 0);
            green  : out std_logic_vector(3 downto 0);
            blue   : out std_logic_vector(3 downto 0)
        );
    end component;

    component vga_test_pattern_12bit is
        port(
            clk    : in  std_logic;
            active : in  std_logic;
            hcount : in  std_logic_vector(10 downto 0);
            vcount : in  std_logic_vector(9 downto 0);
            red    : out std_logic_vector(3 downto 0);
            green  : out std_logic_vector(3 downto 0);
            blue   : out std_logic_vector(3 downto 0)
        );
    end component;

    signal active_s   : std_logic;
    signal hcount_s   : std_logic_vector(10 downto 0);
    signal vcount_s   : std_logic_vector(9 downto 0);
    signal red8_s     : std_logic_vector(3 downto 0);
    signal green8_s   : std_logic_vector(3 downto 0);
    signal blue8_s    : std_logic_vector(3 downto 0);
    signal red12_s    : std_logic_vector(3 downto 0);
    signal green12_s  : std_logic_vector(3 downto 0);
    signal blue12_s   : std_logic_vector(3 downto 0);

begin
    sync_inst : VGA_SYNCer
        port map(
            clk    => clk,
            rst    => rst,
            hsync  => hsync,
            vsync  => vsync,
            active => active_s,
            hcount => hcount_s,
            vcount => vcount_s
        );

    pattern_inst : vga_test_pattern
        port map(
            clk    => clk,
            active => active_s,
            hcount => hcount_s,
            vcount => vcount_s,
            red    => red8_s,
            green  => green8_s,
            blue   => blue8_s
        );

    pattern12_inst : vga_test_pattern_12bit
        port map(
            clk    => clk,
            active => active_s,
            hcount => hcount_s,
            vcount => vcount_s,
            red    => red12_s,
            green  => green12_s,
            blue   => blue12_s
        );

    output_mux : process(pattern_select, red8_s, green8_s, blue8_s, red12_s, green12_s, blue12_s)
    begin
        if pattern_select = '1' then
            red   <= red12_s;
            green <= green12_s;
            blue  <= blue12_s;
        else
            red   <= red8_s;
            green <= green8_s;
            blue  <= blue8_s;
        end if;
    end process output_mux;

end architecture rtl;
