--=============================================================
--Vishal Powell
--ES31/CS56
--=============================================================

--=============================================================
--Library Declarations
--=============================================================
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.numeric_std.ALL;			-- needed for arithmetic
use ieee.math_real.all;				-- needed for automatic register sizing
library UNISIM;						-- needed for the BUFG component
use UNISIM.Vcomponents.ALL;

--============================================================
-- Entity Declaration
--============================================================
entity VGA_top_lvl is 
    port(
        clk_ext_port        : in  std_logic; --ext 100MHZ clk
        -- test_select         : in  std_logic; -- Selects between game state and test screen
        hsync               : out std_logic;
        vsync               : out std_logic;
        red                 : out std_logic_vector(3 downto 0);
        green               : out std_logic_vector(3 downto 0);
        blue                : out std_logic_vector(3 downto 0));
        
     end VGA_top_lvl;

--===========================================================
--Architecture + Component Declarations
--===========================================================
architecture Behavioral of VGA_top_lvl is

    --======================================================
    --                      VGA SYNCER
    --======================================================
    Component VGA is 
        PORT(
            clk             : in std_logic;
            V_SYNC          : out STD_LOGIC;
            H_SYNC          : out STD_LOGIC;
            video_on        : out STD_LOGIC;
            pixel_x     	:	out	STD_LOGIC_vector(9 downto 0);
            pixel_y     	:	out	STD_LOGIC_vector(9 downto 0));


    end component VGA;

    --=======================================================
    --                  VGA TEST PATTERN
    --=======================================================
    component vga_test_pattern is
        port(
            row,column			: in std_logic_vector(9 downto 0);
            color				: out std_logic_vector(11 downto 0));

    end component ;

    --=======================================================
    -- Internal signals
    --=======================================================
    signal pixel_x, pixel_y     : STD_LOGIC_VECTOR(9 downto 0);
    signal video_on             : STD_LOGIC;
    signal color                : STD_LOGIC_VECTOR(11 downto 0);

begin

    uut_VGA: VGA
        port map(
            clk => clk_ext_port,
            V_SYNC => vsync,
            H_SYNC => hsync,
            video_on => video_on,
            pixel_x => pixel_x,
            pixel_y => pixel_y
        );

    uut_vga_test_pattern: vga_test_pattern
        port map(
            row => pixel_y,
            column => pixel_x,
            color => color
        );

    red <= color(11 downto 8) when video_on = '1' else "0000";
    green <= color(7 downto 4) when video_on = '1' else "0000";
    blue <= color(3 downto 0) when video_on = '1' else "0000";

end Behavioral;
