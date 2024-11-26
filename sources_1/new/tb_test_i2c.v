`timescale 1ns / 1ps

module master_i2c_tb;

    // Parameters
    localparam CLK_PERIOD = 10; // 10ns clock period (100MHz)

    // Testbench Signals
    reg [103:0] data_in_tb;
    reg clk_tb;
    reg rst_tb;
    reg enable_tb;
    wire ready_tb;
    wire i2c_sda_tb;
    wire i2c_scl_tb;
    wire done;

    // Instantiate the DUT (Device Under Test)
    master_i2c #(
        .address(7'b0001101)
    ) uut (
        .data_in(data_in_tb),
        .clk(clk_tb),
        .rst(rst_tb),
        .enable(enable_tb),
        .ready(ready_tb),
        .done(done),
        .i2c_sda(i2c_sda_tb),
        .i2c_scl(i2c_scl_tb)
    );
    
    
//	parameter address = 7;
	reg enable;
	reg rw;
	wire ack;


	// internal slave signal
	wire [6:0] slave_addr = 7'b0001101; // slave stored address
	wire [7:0] received_data; // received by the slave
	
	i2c_slave_controller slave (
		.sda(i2c_sda_tb), 
		.scl(i2c_scl_tb),
		.ack(ack), // acknowledge from slave to master
		.data_out(received_data), // data received by slave
		.slave_addr(slave_addr) // slave stored address
	);

    // Generate a clock signal
    initial begin
        clk_tb = 0;
        forever #(CLK_PERIOD / 2) clk_tb = ~clk_tb;
    end

    // Stimulus process
    initial begin
        // Initialize signals
        rst_tb = 1;
        enable_tb = 0;
        data_in_tb = 104'hFFFFFFFFFFFFFFFFFFFFFFFF;
        data_in_tb = 104'h1113556789012345678901234;

        // Apply reset
        #(2 * CLK_PERIOD);
        rst_tb = 0;

        // Provide stimulus
        @(negedge clk_tb);
        enable_tb = 1;


        // Wait for one more I2C transaction to finish
        #7000
        enable_tb = 0;

        // Check data looping (optional - depends on your test scenario)
        #(100 * CLK_PERIOD);
         @(negedge clk_tb);
        enable_tb = 1;
        $finish;
    end

    // Monitor the state of the DUT
    initial begin
        $monitor("Time: %0t | Reset: %b | Enable: %b | Ready: %b | Data_in: %h | SDA: %b | SCL: %b",
                 $time, rst_tb, enable_tb, ready_tb, data_in_tb, i2c_sda_tb, i2c_scl_tb);
    end

    // Optionally, add a pull-up resistor model for the I2C lines
    pullup(i2c_sda_tb);
    pullup(i2c_scl_tb);

endmodule
