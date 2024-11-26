`timescale 1ns / 1ps

module tb_state_machine;

// Clock and reset signals
reg clk;
reg reset;

// UART input
reg [65:0] uart_in;

// Output
wire done;
wire i2c_sda;
wire i2c_scl;
wire complete;
// Instantiate the state machine
state_machine uut (
    .clk(clk),
    .reset(reset),
    .uart_in(uart_in),
    .done(done),
    .complete(complete),
    .i2c_sda(i2c_sda),
    .i2c_scl(i2c_scl)
);





//	parameter address = 7;
	reg enable;
	reg rw;
	wire ack;


	// internal slave signal
	wire [6:0] slave_addr = 7'b0001101; // slave stored address
	wire [7:0] received_data; // received by the slave
	
	i2c_slave_controller slave (
		.sda(i2c_sda), 
		.scl(i2c_scl),
		.ack(ack), // acknowledge from slave to master
		.data_out(received_data), // data received by slave
		.slave_addr(slave_addr) // slave stored address
	);


// Clock generation
initial begin
    clk = 0;
    forever #2.5 clk = ~clk; // 10 ns clock period
end

// Task for applying stimulus to uart_in
task apply_uart_input;
    input [1:0] op;          // opcode for task
    input [31:0] A_val;      // First operand in IEEE 754 format
    input [31:0] B_val;      // Second operand in IEEE 754 format
    begin
        uart_in = {op, A_val, B_val}; // Combine B, A, and opcode
        #10; // Wait for 10 ns to simulate setup time
    end
endtask

// Main test sequence
initial begin
$display("Receiving Data:");
    // Initialize inputs
    reset = 1;
    uart_in = 66'd0;
    
    // Apply reset
    #20 reset = 0; // Release reset after 20 ns

    // Test cases for different numbers
    // A = 5.0 (0x40A00000), B = 3.0 (0x40400000)
    apply_uart_input(2'b00, 32'h40A00000, 32'h40400000); // ADD
    wait(complete);
    apply_uart_input(2'b01, 32'h40A00000, 32'h40400000); // SUBTRACT
    wait(complete);
////    #65
//////    apply_uart_input(2'b10, 32'h40A00000, 32'h40400000); // MULTIPLY
//////    #65
//////    apply_uart_input(2'b11, 32'h40A00000, 32'h40400000); // UNKNOWN
//////    #65

////    // A = 8.0 (0x41000000), B = 3.0 (0x40400000)
//    apply_uart_input(2'b00, 32'h41000000, 32'h40400000); // ADD
//    wait(complete);
//    #65
//    apply_uart_input(2'b01, 32'h41000000, 32'h40400000); // SUBTRACT
//    #65
////    apply_uart_input(2'b10, 32'h41000000, 32'h40400000); // MULTIPLY
////    #65
////    apply_uart_input(2'b11, 32'h41000000, 32'h40400000); // UNKNOWN
////    #65

//    // Edge case: Overflow
//    apply_uart_input(2'b00, 32'h7F800000, 32'h7F800000); // ADD
//    #65
//    apply_uart_input(2'b01, 32'h7F800000, 32'h7F800000); // SUBTRACT
//    #65
////    apply_uart_input(2'b10, 32'h7F800000, 32'h7F800000); // MULTIPLY
////    #65
////    apply_uart_input(2'b11, 32'h7F800000, 32'h7F800000); // UNKNOWN
////    #65

//    // Edge case: Underflow
//    apply_uart_input(2'b00, 32'h00000001, 32'h00000001); // ADD
//    #65
//    apply_uart_input(2'b01, 32'h00000001, 32'h00000001); // SUBTRACT
//    #65
////    apply_uart_input(2'b10, 32'h00000001, 32'h00000001); // MULTIPLY
////    #65
////    apply_uart_input(2'b11, 32'h00000001, 32'h00000001); // UNKNOWN
////    #65

//    // Edge case: NaN
//    apply_uart_input(2'b00, 32'h7FC00000, 32'h40400000); // ADD
//    #65
//    apply_uart_input(2'b01, 32'h7FC00000, 32'h40400000); // SUBTRACT
//    #65
////    apply_uart_input(2'b10, 32'h7FC00000, 32'h40400000); // MULTIPLY
////    #65
////    apply_uart_input(2'b11, 32'h7FC00000, 32'h40400000); // UNKNOWN
////    #65

//    // Edge case: Infinity
//    apply_uart_input(2'b00, 32'h7F800000, 32'hFF800000); // ADD
//    #65
//    apply_uart_input(2'b01, 32'h7F800000, 32'hFF800000); // SUBTRACT
//    #65
////    apply_uart_input(2'b10, 32'h7F800000, 32'hFF800000); // MULTIPLY
////    #65
////    apply_uart_input(2'b11, 32'h7F800000, 32'hFF800000); // UNKNOWN
////    #65

//    // Edge case: Denormalized Numbers
//    apply_uart_input(2'b00, 32'h00000001, 32'h00000002); // ADD
//    #65
//    apply_uart_input(2'b01, 32'h00000001, 32'h00000002); // SUBTRACT
//    #65
//    apply_uart_input(2'b10, 32'h00000001, 32'h00000002); // MULTIPLY
//    #65
//    apply_uart_input(2'b11, 32'h00000001, 32'h00000002); // UNKNOWN
//    #65

    // End of simulation
    $finish;
end

// Monitor state transitions and results
//initial begin
//    $monitor("Time: %0t | State: %0d | Opcode: %b | A: %0e | B: %0e | Done: %b",
//              $time, uut.state, uart_in[1:0], uart_in[33:2], uart_in[65:34], done);
//end
    always @(posedge done) begin
        $display(" %h", received_data);
        end
//    end
endmodule
