`timescale 1ns / 1ps

module i2c_controller_tb;
	reg clk;
	reg rst;
	reg [6:0] addr;
	reg [7:0] data_in;
	reg enable;
	reg rw;
	wire [7:0] data_out;
	wire new_byte_received;
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
		.new_byte_received(new_byte_received),
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
		data_in = 8'd6;
		rw = 0;
		enable = 1;
		#10;
		enable = 0; 
		// Increment data_in and send multiple transactions
		repeat (100) begin
            
			wait(ready)
			data_in = data_in +1; // Increment data_in by 1
			enable = 1;
			#10;
			enable = 0;
			
			#60;
		end
		
        
	

		#50
		$finish;
	end  
   
endmodule


