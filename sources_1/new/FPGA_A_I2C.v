`timescale 1ns / 1ps

parameter [6:0] address = 7;

module FPGA_A_I2C(
    input wire [103:0] data_in,
    input wire clk,
	input wire rst,
	input wire enable,
    output wire ready,
	inout i2c_sda,
	inout wire i2c_scl
 
    );
    wire [7:0] data;
    wire go;
    wire rw;
    reg [7:0] counter;
    reg state;
	i2c_master_controller master (
		.clk(clk), 
		.rst(rst), 
		.addr(address), 
		.data_in(data_in), 
		.enable(go), 
		.rw(rw), 
		.data_out(data_out), 
		.ready(ready), 
		.i2c_sda(i2c_sda), 
		.i2c_scl(i2c_scl)
	);
	
	initial begin
	   counter = 0;
	   state = 0;  
	   rw = 0; 
	end
	
	always @(posedge enable) begin
	       case (state)
        0: begin
            // Initial state or waiting for enable
            if (enable) begin
                data <= data_in[counter_reg];
                counter = counter + 1;
                if(counter > 103) counter =0;
                state <= 1; // Move to next state
            end
        end
        1: begin
            // Wait for the ready signal
            if (ready) begin
                state = 0; 
	    end
	end 
	
endmodule
