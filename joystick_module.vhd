--=============================================================
--Originally by Ben Dobbins
--ES31/CS56
--This script was designed for the SPI Receiver code for Lab 6, the voltmeter and edited for Whack-A-Mole.
--Your name goes here: Vishal Powell
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

--=============================================================
--Entitity Declarations
--=============================================================
entity JoyStick is
	 generic(
	 	N_SHIFTS     				: integer);
	port(
	    --25 MHz serial clock
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
end JoyStick; 

--=============================================================
--Architecture + Component Declarations
--=============================================================
architecture Behavioral of JoyStick is
--=============================================================
--Local Signal Declaration
--=============================================================
signal take_sample          : std_logic := '0';
-- signal shift_x1_enable		: std_logic := '0';
-- signal shift_y1_enable		: std_logic := '0';
-- signal shift_x2_enable		: std_logic := '0';
-- signal shift_y2_enable		: std_logic := '0';
-- signal shift_buttons_enable	: std_logic := '0';
-- signal x_1_reg              : std_logic_vector(7 downto 0) := (others => '0');
-- signal y_1_reg              : std_logic_vector(7 downto 0) := (others => '0');
-- signal x_2_reg              : std_logic_vector(7 downto 0) := (others => '0');
-- signal y_2_reg              : std_logic_vector(7 downto 0) := (others => '0');
-- signal temp_buttons_reg     : std_logic_vector(7 downto 0) := (others => '0');
signal shift_enable		    : std_logic := '0';
signal load_enable		    : std_logic := '0';
signal delay_enable		    : std_logic := '0';
signal shift_reg	        : std_logic_vector(39 downto 0) := (others => '0');
signal x_axis_reg           : std_logic_vector(9 downto 0) := (others => '0');
signal y_axis_reg           : std_logic_vector(9 downto 0) := (others => '0');
signal button_reg           : std_logic_vector(2 downto 0) := (others => '0');
signal clk_divider_cntr     : integer := 0;
signal clk_divider_tc       : std_logic := '0';	-- terminal count for clock divider
signal delay_cntr           : integer := 0;
signal delay_tc             : std_logic := '0';	-- terminal count for SS delay
signal bit_count		    : integer := 0;
signal bit_tc			    : std_logic := '0';	-- terminal count for bit counter
signal shift_cntr           : integer := 0;
signal N_SHIFT_TC           : std_logic := '0';	-- terminal count for number of shifts
signal spi_sclk             : std_logic := '0';

CONSTANT DELAY_COUNT : integer := 375; -- 15us delay at 25MHz clock per spec
CONSTANT N_BITS      : integer := 8; -- Number of bits to shift in
--CONSTANT N_SHIFTS    : integer := 5; -- Number of shifts to perform (5 bytes)


type state_type is (IDLE, SHIFT, DONE, SS_DELAY, DELAY, PARSE);
signal current_state, next_state : state_type := IDLE;

begin
--=============================================================
--Controller:

clk_divider: process(clk_port)
begin
    if rising_edge(clk_port) then
        if clk_divider_cntr + 1 < 25 then
            clk_divider_cntr <= clk_divider_cntr + 1;
            clk_divider_tc <= '0';
        else
            clk_divider_cntr <= 0;
            clk_divider_tc <= '1';
        end if;
    end if;
end process clk_divider;

-- make another process to have a 50-ish% duty signal that i connect to SCKL

SCLK_generator: process(clk_port)
begin
    if rising_edge(clk_port) then
        if shift_enable = '1' then
            if clk_divider_cntr + 1 < 12 then
                spi_sclk <= '0';
            else
                spi_sclk <= '1';
            end if;
        else
            spi_sclk <= '0';
        end if;
    end if;
end process SCLK_generator;

take_sample_sync: process(clk_port,take_sample_port,clk_divider_tc)
begin
    if rising_edge(clk_port) then
        if clk_divider_tc = '1' then
            take_sample <= take_sample_port;
        end if;
    end if;
end process take_sample_sync;

--=============================================================
--+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
--State Update:
--+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++		

state_update: process(clk_port,clk_divider_tc)
begin
    if rising_edge(clk_port) then
        if clk_divider_tc = '1' then --idk how to make this work with the clock divider external so im doing it here.
            current_state <= next_state;
        end if;
    end if;
end process state_update;

--+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
--Next State Logic:
--+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

next_state_process: process(current_state, take_sample, bit_tc, delay_tc,N_SHIFT_TC)
begin
    next_state <= current_state;	-- default state is to hold
    case current_state is
        
        when IDLE =>
            if take_sample = '1' then 
                next_state <= SS_DELAY;
            end if;
        when SS_DELAY =>
            if delay_tc = '1' then
                next_state <= SHIFT;
            end if;
        when SHIFT =>
            if bit_tc = '1' and N_SHIFT_TC = '0' then 
                next_state <= DELAY;
            elsif bit_tc = '1' and N_SHIFT_TC = '1' then
                next_state <= PARSE;
            end if;
        when DELAY =>
            if delay_tc = '1' then
                next_state <= SHIFT;
            end if;
        when PARSE =>
            next_state <= DONE;
        when DONE =>
            next_state <= IDLE;
        when others => null;
    end case;
end process next_state_process;
--+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
--Output Logic:
--+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
Output_process: process (current_state)
begin
    --Default output values
    shift_enable <= '0';
    load_enable <= '0';
    delay_enable <= '0';
    spi_cs_port <= '1';		-- active low

    case current_state is
        when IDLE =>
            spi_cs_port <= '1';		-- active low
        when SS_DELAY =>
            delay_enable <= '1';
            spi_cs_port <= '0';		-- active low
        when SHIFT =>
            shift_enable <= '1';
            spi_cs_port <= '0';		-- active low
        when DELAY =>
            delay_enable <= '1';
            spi_cs_port <= '0';		-- active low
        when PARSE =>
            load_enable <= '1';
        when DONE =>
            null;
        when others => null;
    end case;
end process Output_process;

--+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
--Timer Sub-routines:
--+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

fifteen_us_delay: process(clk_port, delay_enable, clk_divider_tc,delay_cntr)
begin
    -- Implementation for 15 microsecond delay
    if rising_edge(clk_port) then
        if clk_divider_tc = '1' then
            if delay_enable = '1' then
                if delay_cntr < DELAY_COUNT-1 then
                    delay_cntr <= delay_cntr + 1;
                    delay_tc <= '0';
                else
                    delay_cntr <= 0;
                    delay_tc <= '1';
                end if;
            else
            delay_cntr <= 0;
            delay_tc <= '0';
            end if;
        end if;
    end if;
end process fifteen_us_delay;

--=============================================================
--Datapath:
--=============================================================

shift_register: process(clk_port,shift_enable,bit_tc,clk_divider_tc)
begin
    if rising_edge(clk_port) then
        if clk_divider_tc = '1' then
            if shift_enable = '1' then
                shift_reg <= shift_reg(38 downto 0) & spi_s_data_port;
                if bit_count + 1 = N_BITS then
                    bit_count <= 0;
                    if shift_cntr + 1 = N_SHIFTS then
                        shift_cntr <= 0;
                    else
                        shift_cntr <= shift_cntr + 1;
                     end if;
                else
                    bit_count <= bit_count + 1;
                end if;
            end if;
        end if;
    end if;
end process shift_register;

bit_tc<= '1' when bit_count = N_BITS-1 else '0';
N_SHIFT_TC <= '1' when shift_cntr = N_SHIFTS-1 else '0';

Parse_process: process(clk_port,load_enable,clk_divider_tc)
begin
    if rising_edge(clk_port) then
        if clk_divider_tc = '1' then
            if load_enable = '1' then
                x_axis_reg <= shift_reg(25 downto 24) & shift_reg(39 downto 32); -- concatenating the two nibbles for x.
                y_axis_reg <= shift_reg(9 downto 8) & (shift_reg(23 downto 16)); -- concatenating the two nibbles for y.
                button_reg <= shift_reg(2 downto 0); -- the last 3 bits are the buttons and Joystick moved.
            end if;
        end if;
    end if;
end process Parse_process;

--==========================================
--          Handle_outputs
--===========================================

    x_axis_port <= x_axis_reg;
    y_axis_port <= y_axis_reg;
    button_port <= button_reg;
    right_move <= '1' when unsigned(x_axis_reg) > unsigned("1001100100") else '0'; -- if x is greater than 612, we're moving right. => implies 100 deadzone (~7.5% of 1023) on either side of the center value of 512.
    left_move <= '1' when unsigned(x_axis_reg) < unsigned("0110011100") else '0'; -- if x is less than 412, we're moving left.
    up <= '1' when unsigned(y_axis_reg) > unsigned("1001100100") else '0'; -- if y is greater than 612, we're moving up.
    down <= '1' when unsigned(y_axis_reg) < unsigned("0110011100") else '0'; -- if y is less than 412, we're moving down.
    reset_button <= '1' when button_reg(1) = '1' else '0'; -- if the first button bit is 1, reset button is pressed.
    whack_button <= '1' when button_reg(2) = '1' else '0'; -- if the second button bit is 1, start/stop button is pressed.

    spi_sclk_port <= spi_sclk; -- output the generated SCLK to the port.
end Behavioral; 
