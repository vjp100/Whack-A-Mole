## 100MHz clock
set_property PACKAGE_PIN W5 [get_ports clk_ext_port]
set_property IOSTANDARD LVCMOS33 [get_ports clk_ext_port]
create_clock -add -name sys_clk_pin -period 10.00 -waveform {0 5} [get_ports clk_ext_port]

## VGA Hsync / Vsync
set_property PACKAGE_PIN P19 [get_ports hsync]
set_property IOSTANDARD LVCMOS33 [get_ports hsync]
set_property PACKAGE_PIN R19 [get_ports vsync]
set_property IOSTANDARD LVCMOS33 [get_ports vsync]

## VGA Red
set_property PACKAGE_PIN G19 [get_ports {red[0]}]
set_property PACKAGE_PIN H19 [get_ports {red[1]}]
set_property PACKAGE_PIN J19 [get_ports {red[2]}]
set_property PACKAGE_PIN N19 [get_ports {red[3]}]
set_property IOSTANDARD LVCMOS33 [get_ports {red[*]}]

## VGA Green
set_property PACKAGE_PIN J17 [get_ports {green[0]}]
set_property PACKAGE_PIN H17 [get_ports {green[1]}]
set_property PACKAGE_PIN G17 [get_ports {green[2]}]
set_property PACKAGE_PIN D17 [get_ports {green[3]}]
set_property IOSTANDARD LVCMOS33 [get_ports {green[*]}]

## VGA Blue
set_property PACKAGE_PIN N18 [get_ports {blue[0]}]
set_property PACKAGE_PIN L18 [get_ports {blue[1]}]
set_property PACKAGE_PIN K18 [get_ports {blue[2]}]
set_property PACKAGE_PIN J18 [get_ports {blue[3]}]
set_property IOSTANDARD LVCMOS33 [get_ports {blue[*]}]
## For mux switch
set_property PACKAGE_PIN V17 [get_ports test_select]
set_property IOSTANDARD LVCMOS33 [get_ports test_select]

set_property -dict {PACKAGE_PIN W7 IOSTANDARD LVCMOS33} [get_ports {seg[0]}]
set_property -dict {PACKAGE_PIN W6 IOSTANDARD LVCMOS33} [get_ports {seg[1]}]
set_property -dict {PACKAGE_PIN U8 IOSTANDARD LVCMOS33} [get_ports {seg[2]}]
set_property -dict {PACKAGE_PIN V8 IOSTANDARD LVCMOS33} [get_ports {seg[3]}]
set_property -dict {PACKAGE_PIN U5 IOSTANDARD LVCMOS33} [get_ports {seg[4]}]
set_property -dict {PACKAGE_PIN V5 IOSTANDARD LVCMOS33} [get_ports {seg[5]}]
set_property -dict {PACKAGE_PIN U7 IOSTANDARD LVCMOS33} [get_ports {seg[6]}]
set_property -dict {PACKAGE_PIN V7 IOSTANDARD LVCMOS33} [get_ports dp]
set_property -dict {PACKAGE_PIN U2 IOSTANDARD LVCMOS33} [get_ports {an[0]}]
set_property -dict {PACKAGE_PIN U4 IOSTANDARD LVCMOS33} [get_ports {an[1]}]
set_property -dict {PACKAGE_PIN V4 IOSTANDARD LVCMOS33} [get_ports {an[2]}]
set_property -dict {PACKAGE_PIN W4 IOSTANDARD LVCMOS33} [get_ports {an[3]}]

set_property -dict {PACKAGE_PIN A14 IOSTANDARD LVCMOS33} [get_ports jstk_cs]    ;# JB1 -> ~CS
set_property -dict {PACKAGE_PIN A16 IOSTANDARD LVCMOS33} [get_ports jstk_mosi]  ;# JB2 -> MOSI
set_property -dict {PACKAGE_PIN B15 IOSTANDARD LVCMOS33} [get_ports jstk_miso]  ;# JB3 -> MISO
set_property -dict {PACKAGE_PIN B16 IOSTANDARD LVCMOS33} [get_ports jstk_sclk]  ;# JB4 -> SCK

set_property CFGBVS VCCO [current_design]
set_property CONFIG_VOLTAGE 3.3 [current_design]
