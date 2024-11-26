# ### Pin constraints for OLED
# set_property IOSTANDARD LVCMOS18 [get_ports CLK]
# set_property IOSTANDARD LVCMOS18 [get_ports RST]
# set_property IOSTANDARD LVCMOS18 [get_ports EN]
set_property IOSTANDARD LVCMOS18 [get_ports CS]
set_property IOSTANDARD LVCMOS18 [get_ports SDIN]
set_property IOSTANDARD LVCMOS18 [get_ports SCLK]
set_property IOSTANDARD LVCMOS18 [get_ports DC]
set_property IOSTANDARD LVCMOS18 [get_ports RES]
set_property IOSTANDARD LVCMOS18 [get_ports VBAT]
set_property IOSTANDARD LVCMOS18 [get_ports VDD]
set_property IOSTANDARD LVCMOS18 [get_ports FIN]
# set_property PACKAGE_PIN W5 [get_ports CLK]
# set_property PACKAGE_PIN U18 [get_ports RST]
# set_property PACKAGE_PIN W19 [get_ports EN]
set_property PACKAGE_PIN A14 [get_ports CS]
set_property PACKAGE_PIN A16 [get_ports SDIN]
set_property PACKAGE_PIN B16 [get_ports SCLK]
set_property PACKAGE_PIN A15 [get_ports DC]
set_property PACKAGE_PIN A17 [get_ports RES]
set_property PACKAGE_PIN C15 [get_ports VBAT]
set_property PACKAGE_PIN C16 [get_ports VDD]
set_property PACKAGE_PIN L1 [get_ports FIN]


# set_property PACKAGE_PIN V16 [get_ports {SW[3]}]
# set_property PACKAGE_PIN V17 [get_ports {SW[2]}]
# set_property PACKAGE_PIN W16 [get_ports {SW[1]}]
# set_property PACKAGE_PIN W17 [get_ports {SW[0]}]
# set_property IOSTANDARD LVCMOS18 [get_ports {SW[3]}]
# set_property IOSTANDARD LVCMOS18 [get_ports {SW[2]}]
# set_property IOSTANDARD LVCMOS18 [get_ports {SW[1]}]
# set_property IOSTANDARD LVCMOS18 [get_ports {SW[0]}]


# set_property IOSTANDARD LVCMOS18 [get_ports {write_pointer[*]}]
# set_property PACKAGE_PIN U16 [get_ports {write_pointer[0]}]
# set_property PACKAGE_PIN E19 [get_ports {write_pointer[1]}]
# set_property PACKAGE_PIN U19 [get_ports {write_pointer[2]}]
# set_property PACKAGE_PIN V19 [get_ports {write_pointer[3]}]


# set_property IOSTANDARD LVCMOS18 [get_ports {read_pointer[*]}]
# set_property PACKAGE_PIN W18 [get_ports {read_pointer[0]}]
# set_property PACKAGE_PIN U15 [get_ports {read_pointer[1]}]
# set_property PACKAGE_PIN U14 [get_ports {read_pointer[2]}]
# set_property PACKAGE_PIN V14 [get_ports {read_pointer[3]}]

# set_property IOSTANDARD LVCMOS18 [get_ports rx_irq]
# set_property PACKAGE_PIN T18 [get_ports rx_irq]

# set_property IOSTANDARD LVCMOS18 [get_ports tx_irq]
# set_property PACKAGE_PIN U17 [get_ports tx_irq]


# # starting from SW08
# set_property IOSTANDARD LVCMOS18 [get_ports {rx_data[*]}]
# set_property PACKAGE_PIN V2 [get_ports {rx_data[0]}]
# set_property PACKAGE_PIN T3 [get_ports {rx_data[1]}]
# set_property PACKAGE_PIN T2 [get_ports {rx_data[2]}]
# set_property PACKAGE_PIN R3 [get_ports {rx_data[3]}]
# set_property PACKAGE_PIN W2 [get_ports {rx_data[4]}]
# set_property PACKAGE_PIN U1 [get_ports {rx_data[5]}]
# set_property PACKAGE_PIN T1 [get_ports {rx_data[6]}]
# set_property PACKAGE_PIN R2 [get_ports {rx_data[7]}]


# add constraints for the following
# module fpga_b_top(
#     input clk,
#     input rst,
#     input [65:0] uart_in,
#     input [31:0] ans
# );

set_property IOSTANDARD LVCMOS18 [get_ports clk]
set_property PACKAGE_PIN W5 [get_ports clk]

set_property IOSTANDARD LVCMOS18 [get_ports rst]
set_property PACKAGE_PIN U18 [get_ports rst]




set_property IOSTANDARD LVCMOS18 [get_ports sda]
set_property PACKAGE_PIN K17 [get_ports sda]
set_property IOSTANDARD LVCMOS18 [get_ports scl]
set_property PACKAGE_PIN M18 [get_ports scl]




# set_property IOSTANDARD LVCMOS18 [get_ports {mode[*]}]
# set_property PACKAGE_PIN V17 [get_ports {mode[0]}]
# set_property PACKAGE_PIN V16 [get_ports {mode[1]}]



# set_property IOSTANDARD LVCMOS18 [get_ports {ans[*]}]
# set_property PACKAGE_PIN W2 [get_ports {uart_in[0]}]
# set_property PACKAGE_PIN U1 [get_ports {uart_in[1]}]
# set_property PACKAGE_PIN T1 [get_ports {uart_in[2]}]
# set_property PACKAGE_PIN R2 [get_ports {uart_in[3]}]
