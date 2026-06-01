--=============================================================
--Ben Dobbins
--ES31/CS56
--This script is the SPI Receiver code for Lab 6, the voltmeter.
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
entity spi_receiver is
	generic(
		N_SHIFTS 				: integer);
	port(
	    --1 MHz serial clock
		clk_port				: in  std_logic;	
    	
    	--controller signals
		take_sample_port 		: in  std_logic;	
		spi_cs_port			    : out std_logic;
        
        --datapath signals
		spi_s_data_port		    : in  std_logic;	
		adc_data_port			: out std_logic_vector(11 downto 0));
end spi_receiver; 

--=============================================================
--Architecture + Component Declarations
--=============================================================
architecture Behavioral of spi_receiver is
--=============================================================
--Local Signal Declaration
--=============================================================
signal shift_enable		: std_logic := '0';
signal load_enable		: std_logic := '0';
signal shift_reg	    : std_logic_vector(11 downto 0) := (others => '0');
signal bit_count		: integer := 0;
signal bit_tc			: std_logic := '0';	-- terminal count for bit counter
type state_type is (IDLE, SHIFT, LOAD);
signal current_state, next_state : state_type := IDLE;
begin
--=============================================================
--Controller: Finite State Machine
--=============================================================
--+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
--State Update: Synchronous Process
--+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++		

state_update: process(clk_port)
begin
	if rising_edge(clk_port) then
		current_state <= next_state;
	end if;
end process state_update;
--+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
--Next State Logic:
--+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

next_state_process: process(current_state, take_sample_port, bit_tc)
begin
	next_state <= current_state;	-- default state is to hold
	case current_state is
		when IDLE =>
					if take_sample_port = '1' then 
						next_state <= SHIFT;
					end if;
		when SHIFT =>
					if bit_tc = '1' then 
						next_state <= LOAD;
					end if;
		when LOAD =>
					next_state <= IDLE;
	end case;
end process next_state_process;

	

--+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
--Output Logic:
--+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

output_process: process (current_state)
begin
	--Default output values
	shift_enable <= '0';
	load_enable <= '0';
	spi_cs_port <= '1';		-- active low
	
	case current_state is
		when IDLE =>
			spi_cs_port <= '1';		-- active low
		when SHIFT =>
			shift_enable <= '1';
			spi_cs_port <= '0';		-- active low
		when LOAD =>
			load_enable <= '1';
	
	end case;
end process output_process;
--+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
--Timer Sub-routine:
--+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

timer_process: process(clk_port)
begin
	if rising_edge(clk_port) then
		if current_state = SHIFT then
			if bit_count = N_SHIFTS - 2 then
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
end process timer_process;

--=============================================================
--Datapath:
--=============================================================
shift_register: process(clk_port) 
begin
	if rising_edge(clk_port) then
		if shift_enable = '1' then shift_reg <= shift_reg(10 downto 0) & spi_s_data_port;
		end if;
		
		if load_enable = '1' then adc_data_port <= shift_reg;
		end if;
    end if;
end process;
end Behavioral; 