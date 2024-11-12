#### Pin constraints for OLED
set_property IOSTANDARD LVCMOS33 [get_ports CLK]
set_property IOSTANDARD LVCMOS33 [get_ports RST]
set_property PACKAGE_PIN W5 [get_ports CLK]
set_property PACKAGE_PIN U18 [get_ports RST]
set_property PACKAGE_PIN T17 [get_ports remove_btn]
set_property IOSTANDARD LVCMOS33 [get_ports remove_btn]

#7 segment display
set_property PACKAGE_PIN W7 [get_ports {seg[0]}]
set_property IOSTANDARD LVCMOS33 [get_ports {seg[0]}]
set_property PACKAGE_PIN W6 [get_ports {seg[1]}]
set_property IOSTANDARD LVCMOS33 [get_ports {seg[1]}]
set_property PACKAGE_PIN U8 [get_ports {seg[2]}]
set_property IOSTANDARD LVCMOS33 [get_ports {seg[2]}]
set_property PACKAGE_PIN V8 [get_ports {seg[3]}]
set_property IOSTANDARD LVCMOS33 [get_ports {seg[3]}]
set_property PACKAGE_PIN U5 [get_ports {seg[4]}]
set_property IOSTANDARD LVCMOS33 [get_ports {seg[4]}]
set_property PACKAGE_PIN V5 [get_ports {seg[5]}]
set_property IOSTANDARD LVCMOS33 [get_ports {seg[5]}]
set_property PACKAGE_PIN U7 [get_ports {seg[6]}]
set_property IOSTANDARD LVCMOS33 [get_ports {seg[6]}]

set_property PACKAGE_PIN U2 [get_ports {an[0]}]
set_property IOSTANDARD LVCMOS33 [get_ports {an[0]}]
set_property PACKAGE_PIN U4 [get_ports {an[1]}]
set_property IOSTANDARD LVCMOS33 [get_ports {an[1]}]
set_property PACKAGE_PIN V4 [get_ports {an[2]}]
set_property IOSTANDARD LVCMOS33 [get_ports {an[2]}]
set_property PACKAGE_PIN W4 [get_ports {an[3]}]
set_property IOSTANDARD LVCMOS33 [get_ports {an[3]}]


###___



##___


##set_property PACKAGE_PIN U16 [get_ports FIN]

##### transmitter and reciever pins for Second board
##set_property IOSTANDARD LVCMOS18 [get_ports RxD]
##set_property IOSTANDARD LVCMOS18 [get_ports TxD]
##set_property PACKAGE_PIN J1 [get_ports RxD] # JA1
##set_property PACKAGE_PIN L2 [get_ports TxD] # JA2

##### transmitter and reciever pins for Main board
#set_property IOSTANDARD LVCMOS18 [get_ports RxD]
#set_property IOSTANDARD LVCMOS18 [get_ports TxD]
#set_property PACKAGE_PIN K17 [get_ports RxD]
#set_property PACKAGE_PIN M18 [get_ports TxD]
##
## Button contraints for TX (fifo) and TX_en (multiplier)
#set_property IOSTANDARD LVCMOS18 [get_ports TX]
#set_property IOSTANDARD LVCMOS18 [get_ports TX_en]
#set_property PACKAGE_PIN T18 [get_ports TX]
#set_property PACKAGE_PIN U17 [get_ports TX_en]
## Button layout
##        | TX  |
##   | EN | RST |    |
##        |TX_en|
##
##

#USB-RS232 Interface
set_property -dict {PACKAGE_PIN B18 IOSTANDARD LVCMOS33} [get_ports rx]
set_property -dict {PACKAGE_PIN A18 IOSTANDARD LVCMOS33} [get_ports tx]

# LEDs


#7 Segment Display


## Pins used for UART
#set_property PACKAGE_PIN V16 [get_ports {SW[1]}]
#    set_property IOSTANDARD LVCMOS18 [get_ports {SW[1]}]
#set_property PACKAGE_PIN V17 [get_ports {SW[0]}]
#    set_property IOSTANDARD LVCMOS18 [get_ports {SW[0]}]
#set_property DRIVE 12 [get_ports UART_TX]
#set_property PACKAGE_PIN B18 [get_ports UART_RX]
#    set_property IOSTANDARD LVCMOS18 [get_ports UART_RX]
#set_property PACKAGE_PIN A18 [get_ports UART_TX]
#    set_property IOSTANDARD LVCMOS18 [get_ports UART_TX]
#    create_clock -add -name sys_clk_pin -period 20.00 -waveform {0 5} [get_ports CLK]

#set_property PACKAGE_PIN W3 [get_ports {cntr[0]}]
#set_property PACKAGE_PIN U3 [get_ports {cntr[1]}]
#set_property PACKAGE_PIN P3 [get_ports {cntr[2]}]
#set_property PACKAGE_PIN N3 [get_ports {cntr[3]}]
#set_property PACKAGE_PIN P1 [get_ports {cntr[4]}]
#set_property PACKAGE_PIN L1 [get_ports {cntr[5]}]
#set_property IOSTANDARD LVCMOS18 [get_ports {cntr[0]}]
#set_property IOSTANDARD LVCMOS18 [get_ports {cntr[1]}]
#set_property IOSTANDARD LVCMOS18 [get_ports {cntr[2]}]
#set_property IOSTANDARD LVCMOS18 [get_ports {cntr[3]}]
#set_property IOSTANDARD LVCMOS18 [get_ports {cntr[4]}]
#set_property IOSTANDARD LVCMOS18 [get_ports {cntr[5]}]

#set_property PACKAGE_PIN V14 [get_ports {rx_pointer[0]}]
#set_property PACKAGE_PIN V13 [get_ports {rx_pointer[1]}]
#set_property PACKAGE_PIN V3  [get_ports {rx_pointer[2]}]
#set_property IOSTANDARD LVCMOS18 [get_ports {rx_pointer[0]}]
#set_property IOSTANDARD LVCMOS18 [get_ports {rx_pointer[1]}]
#set_property IOSTANDARD LVCMOS18 [get_ports {rx_pointer[2]}]


#set_property PACKAGE_PIN V19 [get_ports {tx_pointer[0]}]
#set_property PACKAGE_PIN W18 [get_ports {tx_pointer[1]}]
#set_property PACKAGE_PIN V15 [get_ports {tx_pointer[2]}]
#set_property IOSTANDARD LVCMOS18 [get_ports {tx_pointer[0]}]
#set_property IOSTANDARD LVCMOS18 [get_ports {tx_pointer[1]}]
#set_property IOSTANDARD LVCMOS18 [get_ports {tx_pointer[2]}]



set_property PACKAGE_PIN V14 [get_ports {LED[7]}]
set_property IOSTANDARD LVCMOS33 [get_ports LED15]
set_property IOSTANDARD LVCMOS33 [get_ports {LED[7]}]
set_property IOSTANDARD LVCMOS33 [get_ports {LED[6]}]
set_property IOSTANDARD LVCMOS33 [get_ports {LED[5]}]
set_property IOSTANDARD LVCMOS33 [get_ports {LED[4]}]
set_property IOSTANDARD LVCMOS33 [get_ports {LED[3]}]
set_property IOSTANDARD LVCMOS33 [get_ports {LED[2]}]
set_property IOSTANDARD LVCMOS33 [get_ports {LED[1]}]
set_property IOSTANDARD LVCMOS33 [get_ports {LED[0]}]
set_property PACKAGE_PIN L1 [get_ports LED15]
set_property PACKAGE_PIN U14 [get_ports {LED[6]}]
set_property PACKAGE_PIN U15 [get_ports {LED[5]}]
set_property PACKAGE_PIN W18 [get_ports {LED[4]}]
set_property PACKAGE_PIN V19 [get_ports {LED[3]}]
set_property PACKAGE_PIN U19 [get_ports {LED[2]}]
set_property PACKAGE_PIN E19 [get_ports {LED[1]}]
set_property PACKAGE_PIN U16 [get_ports {LED[0]}]

set_property PACKAGE_PIN U17 [get_ports btn]
set_property IOSTANDARD LVCMOS33 [get_ports btn]

set_property IOSTANDARD LVCMOS33 [get_ports {SW[3]}]
set_property IOSTANDARD LVCMOS33 [get_ports {SW[2]}]
set_property IOSTANDARD LVCMOS33 [get_ports {SW[1]}]
set_property IOSTANDARD LVCMOS33 [get_ports {SW[0]}]
set_property PACKAGE_PIN A14 [get_ports CS]
set_property PACKAGE_PIN A15 [get_ports DC]
set_property PACKAGE_PIN W19 [get_ports EN]
set_property IOSTANDARD LVCMOS33 [get_ports CS]
set_property IOSTANDARD LVCMOS33 [get_ports DC]
set_property IOSTANDARD LVCMOS33 [get_ports EN]
set_property PACKAGE_PIN B15 [get_ports FIN]
set_property PACKAGE_PIN A17 [get_ports RES]
#set_property PACKAGE_PIN T18 [get_ports reset]
set_property IOSTANDARD LVCMOS33 [get_ports FIN]
set_property IOSTANDARD LVCMOS33 [get_ports RES]
#set_property IOSTANDARD LVCMOS33 [get_ports reset]
set_property PACKAGE_PIN B16 [get_ports SCLK]
set_property PACKAGE_PIN A16 [get_ports SDIN]
set_property PACKAGE_PIN C15 [get_ports VBAT]
set_property PACKAGE_PIN C16 [get_ports VDD]
set_property IOSTANDARD LVCMOS33 [get_ports SCLK]
set_property IOSTANDARD LVCMOS33 [get_ports SDIN]
set_property IOSTANDARD LVCMOS33 [get_ports VBAT]
set_property IOSTANDARD LVCMOS33 [get_ports VDD]
set_property PACKAGE_PIN V17 [get_ports {SW[0]}]
set_property PACKAGE_PIN W17 [get_ports {SW[3]}]
set_property PACKAGE_PIN W16 [get_ports {SW[2]}]
set_property PACKAGE_PIN V16 [get_ports {SW[1]}]


##Pmod Header JA
set_property -dict {PACKAGE_PIN J1 IOSTANDARD LVCMOS33} [get_ports {JA[0]}]
set_property -dict {PACKAGE_PIN L2 IOSTANDARD LVCMOS33} [get_ports {JA[1]}]
set_property -dict {PACKAGE_PIN J2 IOSTANDARD LVCMOS33} [get_ports {JA[2]}]
set_property -dict {PACKAGE_PIN G2 IOSTANDARD LVCMOS33} [get_ports {JA[3]}]
set_property -dict {PACKAGE_PIN H1 IOSTANDARD LVCMOS33} [get_ports {JA[4]}]
set_property -dict {PACKAGE_PIN K2 IOSTANDARD LVCMOS33} [get_ports {JA[5]}]
set_property -dict {PACKAGE_PIN H2 IOSTANDARD LVCMOS33} [get_ports {JA[6]}]
set_property -dict {PACKAGE_PIN G3 IOSTANDARD LVCMOS33} [get_ports {JA[7]}]

create_clock -period 10.000 -name CLK -waveform {0.000 5.000} [get_ports CLK]
create_generated_clock -name clkDivide/LED15_OBUF -source [get_ports CLK] -divide_by 10000000 [get_pins clkDivide/clk_1Hz_reg/Q]
create_clock -period 100000000.000 -name VIRTUAL_clkDivide/LED15_OBUF -waveform {0.000 50000000.000}
set_input_delay -clock [get_clocks CLK] -min -add_delay 2.000 [get_ports {SW[*]}]
set_input_delay -clock [get_clocks CLK] -max -add_delay 2.000 [get_ports {SW[*]}]
set_input_delay -clock [get_clocks CLK] -min -add_delay 2.000 [get_ports EN]
set_input_delay -clock [get_clocks CLK] -max -add_delay 2.000 [get_ports EN]
set_input_delay -clock [get_clocks VIRTUAL_clkDivide/LED15_OBUF] -min -add_delay 2.000 [get_ports EN]
set_input_delay -clock [get_clocks VIRTUAL_clkDivide/LED15_OBUF] -max -add_delay 2.000 [get_ports EN]
set_input_delay -clock [get_clocks CLK] -min -add_delay 2.000 [get_ports RST]
set_input_delay -clock [get_clocks CLK] -max -add_delay 2.000 [get_ports RST]
set_input_delay -clock [get_clocks VIRTUAL_clkDivide/LED15_OBUF] -min -add_delay 2.000 [get_ports RST]
set_input_delay -clock [get_clocks VIRTUAL_clkDivide/LED15_OBUF] -max -add_delay 2.000 [get_ports RST]
set_input_delay -clock [get_clocks CLK] -min -add_delay 2.000 [get_ports btn]
set_input_delay -clock [get_clocks CLK] -max -add_delay 2.000 [get_ports btn]
set_input_delay -clock [get_clocks VIRTUAL_clkDivide/LED15_OBUF] -min -add_delay 2.000 [get_ports remove_btn]
set_input_delay -clock [get_clocks VIRTUAL_clkDivide/LED15_OBUF] -max -add_delay 2.000 [get_ports remove_btn]
set_input_delay -clock [get_clocks CLK] -min -add_delay 2.000 [get_ports rx]
set_input_delay -clock [get_clocks CLK] -max -add_delay 2.000 [get_ports rx]
set_output_delay -clock [get_clocks VIRTUAL_clkDivide/LED15_OBUF] -min -add_delay 0.000 [get_ports {JA[*]}]
set_output_delay -clock [get_clocks VIRTUAL_clkDivide/LED15_OBUF] -max -add_delay 2.000 [get_ports {JA[*]}]
set_output_delay -clock [get_clocks VIRTUAL_clkDivide/LED15_OBUF] -min -add_delay 0.000 [get_ports {LED[*]}]
set_output_delay -clock [get_clocks VIRTUAL_clkDivide/LED15_OBUF] -max -add_delay 2.000 [get_ports {LED[*]}]
set_output_delay -clock [get_clocks CLK] -min -add_delay 0.000 [get_ports {seg[*]}]
set_output_delay -clock [get_clocks CLK] -max -add_delay 2.000 [get_ports {seg[*]}]
set_output_delay -clock [get_clocks CLK] -min -add_delay 0.000 [get_ports CS]
set_output_delay -clock [get_clocks CLK] -max -add_delay 2.000 [get_ports CS]
set_output_delay -clock [get_clocks CLK] -min -add_delay 0.000 [get_ports DC]
set_output_delay -clock [get_clocks CLK] -max -add_delay 2.000 [get_ports DC]
set_output_delay -clock [get_clocks CLK] -min -add_delay 0.000 [get_ports FIN]
set_output_delay -clock [get_clocks CLK] -max -add_delay 2.000 [get_ports FIN]
set_output_delay -clock [get_clocks CLK] -min -add_delay 0.000 [get_ports RES]
set_output_delay -clock [get_clocks CLK] -max -add_delay 2.000 [get_ports RES]
set_output_delay -clock [get_clocks CLK] -min -add_delay 0.000 [get_ports SCLK]
set_output_delay -clock [get_clocks CLK] -max -add_delay 2.000 [get_ports SCLK]
set_output_delay -clock [get_clocks CLK] -min -add_delay 0.000 [get_ports SDIN]
set_output_delay -clock [get_clocks CLK] -max -add_delay 2.000 [get_ports SDIN]
set_output_delay -clock [get_clocks CLK] -min -add_delay 0.000 [get_ports VBAT]
set_output_delay -clock [get_clocks CLK] -max -add_delay 2.000 [get_ports VBAT]
set_output_delay -clock [get_clocks CLK] -min -add_delay 0.000 [get_ports VDD]
set_output_delay -clock [get_clocks CLK] -max -add_delay 2.000 [get_ports VDD]
set_output_delay -clock [get_clocks CLK] -min -add_delay 0.000 [get_ports tx]
set_output_delay -clock [get_clocks CLK] -max -add_delay 2.000 [get_ports tx]
