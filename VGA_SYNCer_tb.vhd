-- Code your testbench here
library IEEE;
use IEEE.std_logic_1164.all;

entity VGA_tb is
end VGA_tb;

architecture testbench of VGA_tb is

component VGA IS
PORT ( 	clk		:	in	STD_LOGIC; --100 MHz clock
		V_sync	: 	out	STD_LOGIC;
		H_sync	: 	out	STD_LOGIC;
        video_on:	out	STD_LOGIC;
		pixel_x	:	out	STD_LOGIC;
        pixel_y	:	out	STD_LOGIC);
end component;



signal 	clk		:	STD_LOGIC; --100 MHz clock
signal	V_sync	: 	STD_LOGIC;
signal	H_sync	: 	STD_LOGIC;
signal	video_on:	STD_LOGIC;
signal	pixel_x	:	STD_LOGIC;
signal	pixel_y	:	STD_LOGIC;


begin

uut : VGA PORT MAP(
		clk  => CLK,
		V_sync => V_sync,
        H_sync => H_sync,
        Video_on => video_on,
		pixel_x => pixel_x,
        pixel_y => pixel_y);
    
    
clk_proc : process
BEGIN

  CLK <= '0';
  wait for 5 ns;   

  CLK <= '1';
  wait for 5 ns;

END PROCESS clk_proc;

stim_proc : process
begin
	

	
    wait;
end process stim_proc;
end testbench;