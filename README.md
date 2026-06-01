# Whack-A-Mole
Engs 31 final project. Team members: Alisha Qureshi, Mazvita Nhidza, Vishal Powell 

## Update 30/5/26 : 12:22am

I think I have the VGA sync working. The test code seems to be working correctly. Tad mentioned that I should probably add some sort of MUX right before when we have the gameplay module so that if we mess up the display we can check if we ruined the VGA or just the drawing logic.

---

### To DO:
#### REMOVE `PCLK_CNRT` or `PCLK` and use normal clk for VGA. We're generating a 25mhz clock instead of dividing.
* I think I'll either finish debouncing and working on joystick logic tonight (probaly not gonna happen lowk) or tomorrow morning. It's SPI and idr how to do that lol.
* ADD SYSTEM_CLOCK_GENERATOR and tick_generator to vivado project and instanciate the different clocks...?




