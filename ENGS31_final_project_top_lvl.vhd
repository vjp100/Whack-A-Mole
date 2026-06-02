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
entity Whack_a_mole_top_lvl is 
    port(
        clk_ext_port        : in  std_logic; --ext 100MHZ clk
       --======================================
        --              VGA
        --=====================================      
        -- test_select         : in  std_logic; -- Selects between game state and test screen
        hsync               : out std_logic;
        vsync               : out std_logic;
        red                 : out std_logic_vector(3 downto 0);
        green               : out std_logic_vector(3 downto 0);
        blue                : out std_logic_vector(3 downto 0);
        
        
        --====================================
        --              JoyStick
        --====================================
        
        jstk_cs             : out std_logic;
        jstk_mosi           : out std_logic ;
        jstk_miso           : in std_logic ;
        jstk_sclk           : out std_logic ;
        
        --==============
        --add game logic
        --==============
        
        --===================================
        --             7 seg display
        --===================================
        
        seg                 : out std_logic_vector (6 downto 0);
        dp                  : out std_logic;
        an                  : out std_logic_vector(3 downto 0)
        
        
        );
        
     end Whack_a_mole_top_lvl ;

--===========================================================
--Architecture + Component Declarations
--===========================================================
architecture Behavioral of Whack_a_mole_top_lvl  is

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
    --                  JOYSTICK MODULE
    --=======================================================
    component joystick is 
        port(
            clk_port    				: in  std_logic;	
    	
    	--controller signals
		take_sample_port    		: in  std_logic;	
		spi_cs_port	    		    : out std_logic;
        
        --datapath signals
		spi_s_data_port	   	       : in  std_logic;	
        x_axis_port                : out std_logic_vector(9 downto 0);
        y_axis_port                : out std_logic_vector(9 downto 0);
        right_move                 : out std_logic;
        left_move                  : out std_logic;
        up                         : out std_logic;
        down                       : out std_logic;
        spi_sclk_port              : out std_logic;
        button_port                : out std_logic_vector(2 downto 0);
        reset_button               : out std_logic;
        whack_button               : out std_logic);
        
    end component joystick;

    --=========================================================
    --              System Clock Generator
    --=========================================================
    component system_clock_generator is
        generic(
            CLOCK_DIVIDER_RATIO : integer := 4
        );
        port(
            input_clk_port : in std_logic;
            system_clk_port : out std_logic;
            fwd_clk_port : out std_logic
        );
    end component system_clock_generator;
    
    --=========================================================
    --              Seven seg generator
    --=========================================================
    
    component seven_seg_driver is
        port(
            clk_port        : in std_logic ;
            data_port       : in std_logic_vector(15 downto 0);
            seg_port        : out std_logic_vector(6 downto 0);
            dp_port         : out std_logic ;
            an_port         : out std_logic_vector (3 downto 0)
         );
     end component seven_seg_driver ;
     

    --=======================================================
    -- Internal signals
    --=======================================================
    
    --                      General
    
    signal system_clk           : std_logic ;
    
    --                         VGA
    signal pixel_x, pixel_y     : STD_LOGIC_VECTOR(9 downto 0);
    signal video_on             : STD_LOGIC;
    signal color                : STD_LOGIC_VECTOR(11 downto 0);


    --                      JoyStick
    
    signal jstk_x                :   std_logic_vector (9 downto 0);
    signal jstk_y                :   std_logic_vector (9 downto 0);
    signal jstk_right_move       :   std_logic;
    signal jstk_left_move        :   std_logic;
    signal jstk_up               :   std_logic;
    signal jstk_down             :   std_logic;
    signal jstk_buttons          :   std_logic_vector(2 downto 0);
    signal jstk_reset_button     :   std_logic;
    signal jstk_whack_button     :   std_logic;
    signal jstk_sclk_int         :   std_logic;


   --                       7 seg display
   signal display_value          :  std_logic_vector (15 downto 0);
   

    
begin
    ---------------------------------------------------------------
    --               System Clock Generation
    ---------------------------------------------------------------
    system_clock_gen: system_clock_generator
        generic map ( CLOCK_DIVIDER_RATIO => 4) -- divide 100 MHz by 4 to get 25 MHz
        port map (
            input_clk_port => clk_ext_port,
            system_clk_port => system_clk,
            fwd_clk_port => open
        );
    
    ---------------------------------------------------------------
    --               VGA Syncer
    --------------------------------------------------------------
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

    -----------------------------------------------------
    --              Joystick Module
    -----------------------------------------------------
    uut_Joystick: joystick 
    port map (
        clk_port =>system_clk, 
        take_sample_port => '1', -- always take samples for now
        spi_s_data_port => jstk_miso,
        spi_cs_port   => jstk_cs,
        x_axis_port   => jstk_x,
        y_axis_port   => jstk_y,
        right_move    => jstk_right_move,
        left_move     => jstk_left_move,
        up            => jstk_up,
        down          => jstk_down,
        spi_sclk_port => jstk_sclk_int ,
        button_port   => jstk_buttons,
        reset_button  => jstk_reset_button,
        whack_button  => jstk_whack_button 
       
       );
         
       jstk_mosi <= '0'; -- not sending any data to the joystick for now
       jstk_sclk  <= jstk_sclk_int ;


    -----------------------------------------------------
    --              7 seg Module
    -----------------------------------------------------
    display_value <= "00000" & jstk_x ;     
    uut_sevenseg : seven_seg_driver 
    port map(
        clk_port => system_clk,
        data_port => display_value ,
        seg_port => seg,
        dp_port => dp,
        an_port => an
        );
         
         
         
         

end Behavioral;
