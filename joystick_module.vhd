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

        button_port                : out std_logic_vector(2 downto 0));
end JoyStick; 

--=============================================================
--Architecture + Component Declarations
--=============================================================
architecture Behavioral of JoyStick is
--=============================================================
--Local Signal Declaration
--=============================================================
signal take_sample      : std_logic := '0';
signal shift_x1_enable		: std_logic := '0';
signal shift_y1_enable		: std_logic := '0';
signal shift_x2_enable		: std_logic := '0';
signal shift_y2_enable		: std_logic := '0';
signal shift_buttons_enable	: std_logic := '0';
signal load_enable		: std_logic := '0';
signal delay_enable		: std_logic := '0';
signal shift_reg	    : std_logic_vector(39 downto 0) := (others => '0');
signal x_1_reg           : std_logic_vector(7 downto 0) := (others => '0');
signal y_1_reg           : std_logic_vector(7 downto 0) := (others => '0');
signal x_2_reg           : std_logic_vector(7 downto 0) := (others => '0');
signal y_2_reg           : std_logic_vector(7 downto 0) := (others => '0');
signal temp_buttons_reg       : std_logic_vector(7 downto 0) := (others => '0');
signal x_axis_reg       : std_logic_vector(9 downto 0) := (others => '0');
signal y_axis_reg       : std_logic_vector(9 downto 0) := (others => '0');
signal button_reg       : std_logic_vector(2 downto 0) := (others => '0');
signal clk_divider_cntr : integer := 0;
signal clk_divider_tc   : std_logic := '0';	-- terminal count for clock divider
signal delay_cntr    : integer := 0;
signal delay_tc      : std_logic := '0';	-- terminal count for SS delay
signal bit_count		: integer := 0;
signal bit_tc			: std_logic := '0';	-- terminal count for bit counter

CONSTANT
    DELAY_COUNT : integer := 375; -- 15us delay at 25MHz clock per spec
    N_BITS : integer := 40; -- Number of bits to shift in (5 bytes)
type state_type is (IDLE, SHIFT_X1, SHIFT_Y1, SHIFT_X2, SHIFT_Y2, , SHIFT_BUTTONS, LOAD_x1, LOAD_y1, LOAD_x2, LOAD_y2, LOAD_BUTTONS);
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

take_sample_sync: process(clk_port)
begin
    if rising_edge(clk_port) then
        take_sample <= take_sample_port or take_sample;
    end if;
end process take_sample_sync;

take_sample : process()
begin
    if delay_tc = '1' and current_state = IDLE then
        take_sample <= '1';
    end if;
--=============================================================
--+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
--State Update:
--+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++		

state_update: process(clk_port)
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

next_state_process: process(current_state, take_sample, bit_tc, delay_tc)
begin
    next_state <= current_state;	-- default state is to hold
    case current_state is
        when IDLE =>
            if take_sample = '1' then 
                if delay_tc = '1' then
                    next_state <= SHIFT_X1;
                end if;
            end if;
        when SHIFT_X1 =>
            if bit_tc = '1' then 
                next_state <= LOAD_x1;
            end if;
        when LOAD_x1 =>
            if delay_tc = '1' then
                next_state <= SHIFT_Y1;
            end if;
        when SHIFT_Y1 =>
            if bit_tc = '1' then 
                next_state <= LOAD_y1;
            end if;
        when LOAD_y1 =>
            if delay_tc = '1' then
                next_state <= SHIFT_X2;
            end if;
        when SHIFT_X2 =>
            if bit_tc = '1' then 
                next_state <= LOAD_x2;
            end if;
        when LOAD_x2 =>
            if delay_tc = '1' then
                next_state <= SHIFT_Y2;
            end if;
        when SHIFT_Y2 =>
            if bit_tc = '1' then 
                next_state <= LOAD_y2;
            end if;
        when LOAD_y2 =>
            if delay_tc = '1' then
                next_state <= SHIFT_BUTTONS;
            end if;
        when SHIFT_BUTTONS =>
            if bit_tc = '1' then 
                next_state <= LOAD_BUTTONS;
            end if;
        when LOAD_BUTTONS =>
            next_state <= IDLE;
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
            delay_enable <= '1';
        when SHIFT_X1 =>
            shift_enable <= '1';
            spi_cs_port <= '0';		-- active low
        when LOAD_x1 =>
            load_enable <= '1';
            delay_enable <= '1';
        when SHIFT_Y1 =>
            shift_enable <= '1';
            spi_cs_port <= '0';		-- active low
        when LOAD_y1 =>
            load_enable <= '1';
            delay_enable <= '1';
        when SHIFT_X2 =>
            shift_enable <= '1';
            spi_cs_port <= '0';		-- active low
        when LOAD_x2 =>
            load_enable <= '1';
            delay_enable <= '1';
        when SHIFT_Y2 =>
            shift_enable <= '1';
            spi_cs_port <= '0';		-- active low
        when LOAD_y2 =>
            load_enable <= '1';
        when LOAD_BUTTONS =>
            load_enable <= '1';
        when others => null;
    end case;
end process Output_process;

--+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
--Timer Sub-routines:
--+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

bit_counter: process(clk_port)
begin
    if rising_edge(clk_port) then
        if clk_divider_tc = '1' then
            if shift_enable = '1' then
                if bit_count = N_BITS - 1 then
                    bit_count <= 0;
                    bit_tc <= '1';
                else
                    bit_count <= bit_count + 1;
                    bit_tc <= '0';
                end if;
            else
                bit_count <= 0;
                bit_tc <= '0';
            end if;
        end if;
    end if;
end process bit_counter;

fifteen_us_delay: process(clk_port)
begin
    -- Implementation for 15 microsecond delay
    if rising_edge(clk_port) then
        if clk_divider_tc = '1' then
            if delay_enable = '1' then
                if delay_cntr < DELAY_COUNT then
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
shift_x1_process: process(clk_port, clk_divider_tc)
begin
    if rising_edge(clk_port) then
        if clk_divider_tc = '1' then
            if shift_x1_enable = '1' then
                x_1_reg <=spi_s_data_port;
            end if;
        end if;
    end if;
end process shift_x1_process;

shift_x2_process: process(clk_port, clk_divider_tc)
begin
    if rising_edge(clk_port) then
        if clk_divider_tc = '1' then
            if shift_x2_enable = '1' then
                 x_2_reg <= spi_s_data_port;
            end if;
        end if;
    end if;
end process shift_x2_process;

shift_y1_process: process(clk_port, clk_divider_tc)
begin
    if rising_edge(clk_port) then
        if clk_divider_tc = '1' then
            if shift_y1_enable = '1' then
                y_1_reg <= spi_s_data_port;
            end if;
        end if;
    end if;
end process shift_y1_process;

shift_y2_process: process(clk_port, clk_divider_tc)
begin
    if rising_edge(clk_port) then
        if clk_divider_tc = '1' then
            if shift_y2_enable = '1' then
                y_2_reg <= spi_s_data_port;
            end if;
        end if;
    end if;
end process shift_y2_process;

shift_buttons_process: process(clk_port, clk_divider_tc)
begin
    if rising_edge(clk_port) then
        if clk_divider_tc = '1' then
            if shift_buttons_enable = '1' then
                temp_buttons_reg <= spi_s_data_port;
            end if;
        end if;
    end if;
end process shift_buttons_process;

end Behavioral; 
