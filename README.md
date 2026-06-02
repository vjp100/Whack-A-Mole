# Whack-A-Mole
Engs 31 final project. Team members: Alisha Qureshi, Mazvita Nhidza, Vishal Powell 

## Update 1/6/26 : 11:56pm

IT WORKSSSS. VGA seems set, so does joystick. Need to make the threshold MUCH larger. like even a slight breeze registers as a movement. Will also try to get an LED to light up when it moves enough to be right or left or whatever i think. 

_Actually, it might be worth doing that before changing threshhold._

### To DO:
#### REMOVE `PCLK_CNRT` or `PCLK` and use normal clk for VGA. We're generating a 25mhz clock instead of dividing.
#### NEED to handle MOSI (i think? might be MISO) in top level by tieing them to ground. Also LED bits i think
* ~I think I'll either finish debouncing and working on joystick logic tonight (probaly not gonna happen lowk) or tomorrow morning. It's SPI and idr how to do that lol.~

* ADD SYSTEM_CLOCK_GENERATOR and tick_generator to vivado project and instanciate the different clocks...?
* MAke SCKL signal
* Create a Take sample signal in top lvl that takes a sample every however long (maybe ever ms)

#### For mid sample:

```
signal sampled_bit : std_logic := '0';
constant SAMPLE_POINT : integer := 18;  -- mid high-phase (SCLK high is cntr 11-24)

sample_capture: process(clk_port)
begin
    if rising_edge(clk_port) then
        if clk_divider_cntr = SAMPLE_POINT then
            sampled_bit <= spi_s_data_port;
        end if;
    end if;
end process sample_capture;
```
    also change `shift_reg... &spi...` to `shift_reg <= shift_reg(38 downto 0) & sampled_bit;   -- was spi_s_data_port`

Claude also recommended changing `entity JoyStick`:

```
entity Joystick is
    generic (DELAY_COUNT : integer := 375);   -- default for synthesis
    port( ... );
```
and delete the CONSTANT DELAY_COUNT : integer := 375; line from the architecture.

Cuz it'll be "long to sim with the actual time" or smtn idk

Old Updates:
---
## Update 1/6/26 : 5:34 PM
Lowk should be close to being done. need to make a testbench to work with the file but it's solid? idk will see. 

## Update 1/6/26 : 1:46am

Haven't finished coding Joystick module. Need to include registers for x and y (with the parsing of the data to take the 10 bit entry that's split across 16 bits). Need to do math, thinking of potentially having an x shift register (maybe x1, x2) and then anding them into.

Actually i'll have a generic shift register that takes the whole thing maybe (?? all 40 bytes) then i shift them in to the appropriate space? not sure tbh.

anyways either shift specifically to the registers then format them into only one.
* ~then check if they fit the criteria for left, right, up or down and provide a monopulsed signal for it.~
* ~Idk same for buttons--parse and see if button 1 (start/stop) or 2 (whacked) is pressed.~

## Update 30/5/26 : 12:22am

I think I have the VGA sync working. The test code seems to be working correctly. Tad mentioned that I should probably add some sort of MUX right before when we have the gameplay module so that if we mess up the display we can check if we ruined the VGA or just the drawing logic.


---







