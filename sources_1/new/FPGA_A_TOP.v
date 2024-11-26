`timescale 1ns / 1ps


module FPGA_A_TOP(
    input wire clk,                // Clock input
    input wire btnC,              // Reset signal
    input wire btnD,
    input wire btnL,
    input wire RsRX,
    output wire RsTx,
//    inout [3:0] JA,
    inout sda,
    output scl,
    output [15:0] led
    
    
//   input wire [65:0] uart_in,     // UART input
//    output wire done,              // Done signal from state machine
//    output wire i2c_sda,           // I2C data line
//    output wire i2c_scl,           // I2C clock line
//    output wire complete           // Completion signal
);
    uart_test uart (
        .CLK(clk),
        .reset(reset),
        .rx(RsRX),
        .btn(btnL),
        .tx(RsTx),
        .finished(uart_finished),
        .uart_in(uart_in)
    );
    
    wire uart_finished;
       
   assign led[13] = uart_finished;
    
    
    
// Clock and reset signals

wire reset;
// UART input
wire [65:0] uart_in2;
assign uart_in2 = {2'b01, 32'h40A00000, 32'h40400000};

// Output
wire done;
wire i2c_sda;
wire i2c_scl;
wire complete;
// Instantiate the state machine
state_machine uut (
    .clk(clk),
    .reset(reset),
    .uart_in(uart_in2),
    .uart_ready(btnD),
    .complete(complete),
    .done(done),
    .i2c_sda(sda),
    .i2c_scl(scl),
    .op(opcode),
    .st(st)
);

wire [1:0] opcode;
wire [3:0] st;

assign led[5:2] = st;
assign led[1:0] = opcode;
//assign led[11] = done;
//assign led[9] = complete;
assign led[9:6] = uart_in2[65:62];


//reg uart_in2 = {2'b01, 32'h40A00000, 32'h40400000};
//	parameter address = 7;
	wire enable;
	wire rw;
	wire ack;


	// internal slave signal
	wire [6:0] slave_addr = 7'b0001101; // slave stored address
	wire [7:0] received_data; // received by the slave
	
	i2c_slave_controller slave (
		.sda(sda), 
		.scl(scl),
		.ack(ack), // acknowledge from slave to master
		.data_out(received_data), // data received by slave
		.slave_addr(slave_addr) // slave stored address
	);
	wire M_sda,M_scl, S_sda, S_scl;
   assign reset = btnC;
   assign led[7] = ack;
//   assign JA[0] = M_sda;
//   assign JA[1] = M_scl;
//   assign JA[2] = S_sda;
//   assign JA[3] = S_scl;
   assign led[15] = complete;


endmodule
