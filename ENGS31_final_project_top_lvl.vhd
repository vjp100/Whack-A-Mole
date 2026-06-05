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
        test_select         : in  std_logic; -- Selects between game state and test screen
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
        
--        --====================================
--        -- Datapath/debug outputs
--        --====================================
--        hammer_hole_out     : out std_logic_vector(3 downto 0);
--        mole_hole_out       : out std_logic_vector(3 downto 0);
--        mole_up_out         : out std_logic;

--        score_out           : out std_logic_vector(7 downto 0);
--        misses_out          : out std_logic_vector(1 downto 0);

--        game_on_out         : out std_logic;
--        gameover_screen_out : out std_logic;
--        valid_whack_out     : out std_logic;

--        reset_out           : out std_logic;
        
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
            pixel_x     	: out	STD_LOGIC_vector(9 downto 0);
            pixel_y     	: out	STD_LOGIC_vector(9 downto 0));


    end component VGA;

    --=======================================================
    --                  VGA TEST PATTERN
    --                  eventually replace with sprite driver
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
            clk_port    			: in  std_logic;	
    	
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
    
    signal color        : std_logic_vector(11 downto 0);
    signal test_color   : std_logic_vector(11 downto 0);
    signal render_color : std_logic_vector(11 downto 0);

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
   
    --                 FSM/game datapath signals
    signal game_on_sig          : std_logic;
    signal whacked_sig          : std_logic;
    signal gameover_screen_sig  : std_logic;
    signal reset_sig            : std_logic;

    signal hammer_hole_sig      : std_logic_vector(3 downto 0);
    signal mole_hole_sig        : std_logic_vector(3 downto 0);
    signal mole_up_sig          : std_logic;
    signal valid_whack_sig      : std_logic;
    signal misses_sig           : std_logic_vector(1 downto 0);
    signal score_sig            : std_logic_vector(7 downto 0);
    signal clk_cntr             : integer :=0;
    signal take_sample          : std_logic := '0';
    signal hit_flash_active : std_logic;
    signal hit_flash_hole   : std_logic_vector(3 downto 0);


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
            clk => system_clk ,
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
            color => test_color
        );

    ------------------  MUX to go between game and test pattern --------------
    mux_proc : process(test_select, video_on, test_color, render_color)
    begin
        if test_select = '1' then
            if video_on = '1' then          -- test pattern needs blanking added
                color <= test_color;
            else
                color <= (others => '0');
            end if;
        else
            color <= render_color;          -- renderer already blanked internally
        end if;
    end process;
    
    red   <= color(11 downto 8);
    green <= color(7 downto 4);
    blue  <= color(3 downto 0);

    -----------------------------------------------------
    --              Joystick Module
    -----------------------------------------------------
    uut_Joystick: joystick 
    port map (
        clk_port =>system_clk, 
        take_sample_port => '1' , 
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


     ---------------------------------------------------------------
    -- FSM
    -- Controls idle, playing, whack, and gameover states.
    --
    -- Assumption:
    -- jstk_reset_button is being used as the start/reset-style input.
    -- jstk_whack_button is being used as the whack input.
    ---------------------------------------------------------------
    fsm_inst : entity work.whack_fsm
        port map (
            clk_port        => system_clk,

            start_pressed   => jstk_reset_button,
            whack_pressed   => jstk_whack_button,
            misses          => misses_sig,

            whacked         => whacked_sig,
            game_on         => game_on_sig,
            gameover_screen => gameover_screen_sig,
            reset           => reset_sig
        );

    ---------------------------------------------------------------
    -- Hammer Movement
    -- Joystick direction signals are connected here.
    ---------------------------------------------------------------
    hammer_move_inst : entity work.hammer_move
        port map (
            clk_port    => system_clk,

            up          => jstk_up,
            down        => jstk_down,
            right       => jstk_right_move,
            left        => jstk_left_move,

            game_on     => game_on_sig,

            hammer_hole => hammer_hole_sig
        );

    ---------------------------------------------------------------
    -- Mole Generator
    -- Generates mole position, mole_up, valid_whack, and misses.
    ---------------------------------------------------------------
    mole_generator_inst : entity work.mole_generator
        generic map (
            CLK_FREQ      => 25000000,
            MOLE_TIME_SEC => 2
        )
        port map (
            clk         => system_clk,
            reset       => reset_sig,
            game_on     => game_on_sig,

            whacked     => whacked_sig,
            hammer_hole => hammer_hole_sig,

            mole_hole   => mole_hole_sig,
            mole_up     => mole_up_sig,
            valid_whack => valid_whack_sig,
            misses      => misses_sig,
            hit_flash_active => hit_flash_active,
            hit_flash_hole   => hit_flash_hole
        );

    ---------------------------------------------------------------
    -- Score Counter
    -- Increments score whenever valid_whack is high.
    ---------------------------------------------------------------
    score_counter_inst : entity work.score_counter
        port map (
            clk         => system_clk,
            reset       => reset_sig,
            game_on     => game_on_sig,
            valid_whack => valid_whack_sig,

            score       => score_sig
        );

    -----------------------------------------------------
    -- Seven Segment Display
    --
    -- Left digit: misses
    -- Right 3 digits: score
    --
    -- Example:
    -- misses = 2, score = 015
    -- display shows 2015
    -----------------------------------------------------
    display_proc : process(score_sig, misses_sig)
        variable score_int  : integer range 0 to 255;
        variable misses_int : integer range 0 to 3;
    begin
        score_int  := to_integer(unsigned(score_sig));
        misses_int := to_integer(unsigned(misses_sig));

        display_value <= std_logic_vector(to_unsigned(misses_int, 4)) &
                         std_logic_vector(to_unsigned(score_int / 100, 4)) &
                         std_logic_vector(to_unsigned((score_int / 10) mod 10, 4)) &
                         std_logic_vector(to_unsigned(score_int mod 10, 4));
    end process display_proc;

    uut_sevenseg : seven_seg_driver
        port map(
            clk_port  => system_clk,
            data_port => display_value,
            seg_port  => seg,
            dp_port   => dp,
            an_port   => an
        );

    ----------------------------------------------------------------------------
    --                      Graphic Renderer
    ----------------------------------------------------------------------------
    
--    graphic_renderer_inst : entity work.graphic_renderer
--        port map (
--            clk         => system_clk,
--            reset       => reset_sig,
--            game_on     => game_on_sig,
--            video_on    => video_on,
--            mole_hole   => mole_hole_sig,
--            mole_up     => mole_up_sig,
--            hammer_hole => hammer_hole_sig,
--            whacked     => whacked_sig,
--            x_pixel     => pixel_x,
--            y_pixel     => pixel_y,
--            rgb_out     => render_color
--        );
-- graphic_renderer_inst : entity work.graphic_renderer
--     port map ( ... );    -- commented out for now

renderer_inst : entity work.graphic_renderer
    port map (
        clk         => system_clk,
        reset       => reset_sig,
        video_on    => video_on,

        game_on     => game_on_sig,
        gameover    => gameover_screen_sig,

        mole_hole   => mole_hole_sig,
        mole_up     => mole_up_sig,
        hammer_hole => hammer_hole_sig,
        whacked     => whacked_sig,
        hit_flash_active => hit_flash_active,
        hit_flash_hole   => hit_flash_hole,

        js_up    => jstk_up,
        js_down  => jstk_down,
        js_left  => jstk_left_move,
        js_right => jstk_right_move,
        js_whack => jstk_whack_button,
        js_start => jstk_reset_button,

        score    => score_sig,
        misses   => misses_sig,

        x_pixel  => pixel_x,
        y_pixel  => pixel_y,
        rgb_out  => render_color
    );
-- ---------------------------------------------------------------
--             -- Output Assignments
--    ---------------------------------------------------------------
--    hammer_hole_out     <= hammer_hole_sig;
--    mole_hole_out       <= mole_hole_sig;
--    mole_up_out         <= mole_up_sig;

--    score_out           <= score_sig;
--    misses_out          <= misses_sig;

--    game_on_out         <= game_on_sig;
--    gameover_screen_out <= gameover_screen_sig;
--    valid_whack_out     <= valid_whack_sig;

--    reset_out           <= reset_sig;

         
         
         
         

end Behavioral;
