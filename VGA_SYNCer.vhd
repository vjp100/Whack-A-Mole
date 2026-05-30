-- VGA Synchronization Generator
-- This script is the shell code for ENGS 31 final project, WHACK-A-MOLE
library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

ENTITY VGA IS
PORT ( 	clk		:	in	STD_LOGIC; --100 MHz clock
		V_sync	: 	out	STD_LOGIC;
		H_sync	: 	out	STD_LOGIC;
        video_on:	out	STD_LOGIC;
		pixel_x	:	out	STD_LOGIC_vector(9 downto 0);
        pixel_y	:	out	STD_LOGIC_vector(9 downto 0));
end VGA;


architecture behavior of VGA is

signal pixel_x_out, pixel_y_out : integer := 0;

signal H_video_on : STD_LOGIC := '0';
signal V_video_on : STD_LOGIC := '0';
--Add your signals here

signal PCLK, PCLK_toggle: STD_LOGIC := '0';
signal clk_cnt: integer  := 0;
signal PCLK_cntr : integer := 0;
signal prevPCLK : std_logic:='0';
signal hsync : std_logic := '0';
signal hsync_old : std_logic :='0';
signal hsync_clk : std_logic :='0';
signal vsync : std_logic := '0';
signal vlines : integer := 0;
--VGA Constants (taken directly from VGA Class Notes)

constant left_border : integer := 48;--48 | used 2 for sim w/ vertical
constant h_display : integer := 640;--640 | used 20 for sum w/ vertical
constant right_border : integer := 16;--16| used 2 for sim w/vertical
constant h_retrace : integer := 96;--96	 | used 4 for sim  w/ vertical
constant HSCAN : integer := left_border + h_display + right_border + h_retrace - 1; --number of PCLKs in an H_sync period


constant top_border : integer := 29;--29
constant v_display : integer := 480;---480
constant bottom_border : integer := 10;--10
constant v_retrace : integer := 2;--2
constant VSCAN : integer := top_border + v_display + bottom_border + v_retrace - 1; --number of H_syncs in an V_sync period
BEGIN

PCLK_toggle_func : process(clk)
begin
	if rising_edge(clK) then
    	if clk_cnt + 1 < 2 then
			clk_cnt<=clk_cnt+1;
        else 
        	clk_cnt<= 0;
            PCLK_toggle <= not PCLK_toggle;
        end if;
    end if;
end process PCLK_toggle_func;

 
--PCLK Generating Process
PCLK_proc : process(clk)
begin
	if rising_edge(clk) then
    --put your PCLK generation code here
    	if PCLK_toggle = '1' then
        	PCLK <= '1';
            prevPCLK <= PCLK;
        else 
        	PCLK<='0';
            prevPCLK <= PCLK;
        end if;
    end if;
end process PCLK_proc;

PCLK_cnt_func : process(clk)
begin
	if rising_edge(clk) then
        if (PCLK = '1' ) and (clk_cnt = 0) then
        	if PCLK_cntr  < HSCAN then
        		PCLK_cntr <= PCLK_cntr + 1;
            else 
                PCLK_cntr <= 0;
            end if;
        end if;
    end if;
end process PCLK_cnt_func;

--H_sync generating process
Hsync_proc : process(clk)
begin
	if rising_edge(clk) then
       --H_sync and H_video_on generation code goes here
      -- if PCLK_cntr = 0 or PCLK_cntr = hscan-left_border or PCLK_cntr < HSCAN - h_retrace then
       if (PCLK_cntr < left_border + h_display + right_border) or (PCLK_cntr > HSCAN) then
       		hsync<='1';
            hsync_old<=hsync;
              --elsif PCLK_cntr > HSCAN - h_retrace and PCLK_cntr < HSCAN - left_border then
              else
              	hsync<='0';
                hsync_old<=hsync;
              end if; 
              
       if PCLK_cntr >= left_border and PCLK_cntr < (left_border + h_display) then
       		h_video_on<='1';
       else
       		h_video_on<='0';
       end if;
    end if;
end process Hsync_proc;

--Count number of lines traced
v_lines_func : process (clk,hsync)
begin
	if rising_edge(clk) then
			if hsync_old = '0' and hsync = '1' then
--        	hsync_clk <='1';
			
              if vlines  < VSCAN then
                  vlines<=vlines+1;
              else
                  vlines<=0;
            end if;
         end if;
         --else hsync_clk<='0';
     end if;
end process v_lines_func;
    	


--V_sync generating process
Vsync_proc : process(clk,vlines)
begin
	if rising_edge(clk) then
       --V_sync and V_video_on generation code goes here
       		if hsync_old = '0' and hsync = '1' then
--            if hsync_clk = '1' then
            	if (vlines <=  top_border + v_display + bottom_border) or (vlines >= top_border + v_display + bottom_border + v_retrace  ) then
                	vsync<='1';
                else 
                	vsync<='0';
                end if;
                
              	if vlines >= top_border and vlines <= (top_border + v_display) then
                	v_video_on<='1';
                else 
                	v_video_on<='0';
                end if;
            end if;
       
    end if;
end process Vsync_proc;



pixel_x_out<=PCLK_cntr - left_border when (H_video_on AND V_video_on)='1' else 0;
pixel_y_out<=vlines - top_border when (H_video_on AND V_video_on)='1' else 0;

--==========================================================
--                      OUTPUTS
--==========================================================
pixel_x<=std_logic_vector(to_unsigned(pixel_x_out, 10));
pixel_y<= std_logic_vector(to_unsigned(pixel_y_out, 10));
video_on <= H_video_on AND V_video_on; --Only enable video out when H_video_out and V_video_out are high. It's important to set the output to zero when you aren't actively displaying video. That's how the monitor determines the black level.
v_sync <= vsync;
H_sync <= hsync;
end behavior;
        
        