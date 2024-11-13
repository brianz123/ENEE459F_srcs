`timescale 1ns / 1ps

module tb_state_machine;

// Clock and reset signals
reg clk;
reg reset;

// UART input
reg [65:0] uart_in;

// Output
wire done;

// Instantiate the state machine
state_machine uut (
    .clk(clk),
    .reset(reset),
    .uart_in(uart_in),
    .done(done)
);

// Clock generation
initial begin
    clk = 0;
    forever #5 clk = ~clk; // 10 ns clock period
end

// Task for applying stimulus to uart_in
task apply_uart_input;
    input [1:0] op;          // opcode for task
    input [31:0] A_val;      // First operand in IEEE 754 format
    input [31:0] B_val;      // Second operand in IEEE 754 format
    begin
        uart_in = {B_val, A_val, op}; // Combine B, A, and opcode
        #10; // Wait for 10 ns to simulate setup time
    end
endtask

// Main test sequence
initial begin
    // Initialize inputs
    reset = 1;
    uart_in = 66'd0;
    
    // Apply reset
    #20 reset = 0; // Release reset after 20 ns

    // Test ADD operation (opcode = 0)
    apply_uart_input(2'b00, 32'h40A00000, 32'h40400000); // A = 5.0, B = 3.0 (IEEE 754 format), ADD
    wait(done); // Wait until the task is completed
    #10; // Wait for 10 ns after done signal

    // Test SUBTRACT operation (opcode = 1)
    apply_uart_input(2'b01, 32'h41000000, 32'h40400000); // A = 8.0, B = 3.0, SUBTRACT
    wait(done); // Wait until the task is completed
    #10; // Wait for 10 ns after done signal

    // Test MULTIPLY operation (opcode = 2)
    apply_uart_input(2'b10, 32'h40000000, 32'h40800000); // A = 2.0, B = 4.0, MULTIPLY
    wait(done); // Wait until the task is completed
    #10; // Wait for 10 ns after done signal

    // Reset state machine
    reset = 1;
    #20 reset = 0;

    // Test default (unknown opcode)
    apply_uart_input(2'b11, 32'h40000000, 32'h40800000); // Unknown opcode
    wait(done); // Wait until the task is completed
    #10; // Wait for 10 ns after done signal

    // End of simulation
    $finish;
end

// Monitor state transitions and results
initial begin
    $monitor("Time: %0t | State: %0d | Opcode: %b | A: %0h | B: %0h | Done: %b",
              $time, uut.state, uart_in[1:0], uart_in[33:2], uart_in[65:34], done);
end

endmodule
