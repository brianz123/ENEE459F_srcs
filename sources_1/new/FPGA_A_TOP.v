`timescale 1ns / 1ps


module FPGA_A_TOP(
    input wire clk,                // Clock input
    input wire btnC,              // Reset signal
    input wire btnD,
    input wire btnL,
    input wire RsRX,
    input wire [15:0] sw,
    output wire RsTx,
    inout [3:0] JB,
    inout sda,
    inout scl,
    output [15:0] led
    
    
//   input wire [65:0] uart_in,     // UART input
//    output wire done,              // Done signal from state machine
//    output wire i2c_sda,           // I2C data line
//    output wire i2c_scl,           // I2C clock line
//    output wire complete           // Completion signal
);
//    uart_test uart (
//        .CLK(clk),
//        .reset(reset),
//        .rx(RsRX),
//        .btn(btnL),
//        .tx(RsTx),
//        .finished(uart_finished),
//        .uart_in(uart_in)
//    );
    clk_delay #(
    .DELAY_COUNT(100000) // 5-cycle delay
) u_clk_delay (
    .clk(clk),           // Input clock
    .reset(reset),       // Synchronous reset
    .delayed_clk(out_clk) // Delayed output clock
);
    wire uart_finished;
       
   assign led[13] = uart_finished;
    
    
    
// Clock and reset signals
wire [8:0] debugWire;
wire reset;
// UART input
wire [65:0] uart_in;
wire [65:0] uart_in2;
assign uart_in2 = {2'b01, 32'h12345678, 32'h87654321};

// Output
wire done;
//wire i2c_sda;
//wire i2c_scl;
wire complete;
wire ready;
// Instantiate the state machine
state_machine uut (
    .clk(out_clk),
    .reset(reset),
    .uart_in(uart_in2),
    .uart_ready(sw[0]),
    .data(sw[15:8]),
    .complete(complete),
    .ready(ready),
    .done(done),
    .i2c_sda(sda),
    .i2c_scl(scl),
    .op(opcode),
    .st(st),
    .debugWire(debugWire)
);
//    i2c_master_controller master (
//        .clk(out_clk), 
//        .rst(reset), 
//        .addr(slave_addr), 
//        .data_in(8'b10101010), 
//        .enable(sw[0]), 
//        .rw(0), 
//        .data_out(), // If not used, leave unconnected or specify `data_out` usage
//        .ready(ready), 
//        .done(done),
//        .i2c_sda(sda), 
//        .i2c_scl(scl)
//    );
wire [1:0] opcode;
wire [3:0] st;

assign led[5:2] = st;
assign led[1:0] = opcode;
assign led[11] = done;
assign led[10] = ready;
assign led[14] = debugWire[0];
assign led[13] = clk;
//assign JB[2] = clk;
//assign led[9] = complete;
assign led[9:6] = uart_in2[65:62];
assign JB[0] = sda;
assign JB[1] = scl;
assign JB[2] = complete;

//reg uart_in2 = {2'b01, 32'h40A00000, 32'h40400000};
//	parameter address = 7;
	wire enable;
	wire rw;
	wire ack;


	// internal slave signal
	wire [6:0] slave_addr = 7'b0000111; // slave stored address
	wire [7:0] received_data; // received by the slave
	
//	i2c_slave_controller slave (
//		.sda(sda), 
//		.scl(scl),
//		.ack(ack), // acknowledge from slave to master
//		.data_out(received_data), // data received by slave
//		.slave_addr(slave_addr) // slave stored address
//	);
//	wire M_sda,M_scl, S_sda, S_scl;
   assign reset = btnC;
   assign led[7] = ack;
//   assign JA[0] = M_sda;
//   assign JA[1] = M_scl;
//   assign JA[2] = S_sda;
//   assign JA[3] = S_scl;
   assign led[15] = complete;


endmodule



module clk_delay #(
    parameter DELAY_COUNT = 10 // Number of clock cycles to delay
)(
    input clk,               // Input clock signal
    input reset,             // Synchronous reset
    output reg delayed_clk   // Delayed clock signal
);

// Internal counter
reg [$clog2(DELAY_COUNT):0] counter;

always @(posedge clk or posedge reset) begin
    if (reset) begin
        counter <= 0;
        delayed_clk <= 0;
    end else begin
        if (counter < DELAY_COUNT - 1) begin
            counter <= counter + 1;
        end else begin
            counter <= 0;
            delayed_clk <= ~delayed_clk; // Toggle delayed clock
        end
    end
end

endmodule
