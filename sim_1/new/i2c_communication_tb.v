`timescale 1ns / 1ps

module i2c_controller_tb;
	reg clk;
	reg rst;
	reg [6:0] addr;
	reg [7:0] data_in;
	reg enable;
	reg rw;
	wire [7:0] data_out;
	wire ready;
	wire i2c_sda;
	wire i2c_scl;

	// internal slave signal
	wire ack; // slave ack
	wire [6:0] slave_addr = 7'b0101010; // slave stored address
	wire [7:0] received_data; // received by the slave
	
	i2c_master_controller master (
		.clk(clk), 
		.rst(rst), 
		.addr(addr), 
		.data_in(data_in), 
		.enable(enable), 
		.rw(rw), 
		.data_out(data_out), 
		.ready(ready), 
		.i2c_sda(i2c_sda), 
		.i2c_scl(i2c_scl)
	);

	i2c_slave_controller slave (
		.sda(i2c_sda), 
		.scl(i2c_scl),
		.ack(ack), // acknowledge from slave to master
		.data_out(received_data), // data received by slave
		.slave_addr(slave_addr) // slave stored address
	);
    
	initial begin
		clk = 0;
		forever begin
			clk = #1 ~clk;
		end		
	end

	initial begin
		clk = 0;
		rst = 1;

		#100;
		rst = 0;
		
		addr = 7'b0101010; // match slaves stored address
		data_in = 8'b10101010;
		rw = 0;
		enable = 1;
		#10;
		enable = 0;

		// wait for the slave to respond
		#20;
		if (ack) begin
			$display("Slave Acknowledged the Master.");
		end else begin
			$display("Slave did not Acknowledge.");
		end

		// check if slave received the data correctly
		#20;
		if (received_data == data_in) begin
			$display("Slave successfully received data: %b", received_data);
		end else begin
			$display("Slave failed to receive the correct data.");
		end

		#500
		$finish;
	end      
endmodule
