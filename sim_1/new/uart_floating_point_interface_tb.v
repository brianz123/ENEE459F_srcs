`timescale 1ns / 1ps

module tb_uart_test;

// Testbench signals
reg CLK;              // Clock signal for FPGA
reg reset;            // Reset signal
reg rx;               // UART receive line
reg btn;              // Button to trigger read/write operation

// Outputs from the DUT (Device Under Test)
wire tx;              // UART transmit line
wire [3:0] an;        // 7-segment display digit select
wire [0:6] seg;       // 7-segment display segment control
wire [7:0] LED;       // LED data display

// Instantiate the uart_test module
uart_test uut (
    .CLK(CLK),
    .reset(reset),
    .rx(rx),
    .btn(btn),
    .tx(tx),
    .an(an),
    .seg(seg),
    .LED(LED)
);

// Generate clock signal
initial begin
    CLK = 0;
    forever #5 CLK = ~CLK; // 10 ns clock period (100 MHz)
end

// Main test sequence
initial begin
    // Initialize inputs
    reset = 1;
    btn = 0;
    rx = 1;  // Idle state of UART line (high)
    
    // Hold reset high initially
    #20 reset = 0; // Release reset after 20 ns

    // Simulate UART reception of 'A' (ASCII 65, 8'h41)
    // Start bit (low)
    rx = 0;
    #104160; // Wait for one bit time (9600 baud rate)

    // Data bits for 'A' (ASCII 65, binary 01000001)
    rx = 1; #104160; // LSB = 1
    rx = 0; #104160; // Bit 1 = 0
    rx = 1; #104160; // Bit 2 = 0
    rx = 0; #104160; // Bit 3 = 0
    rx = 1; #104160; // Bit 4 = 0
    rx = 0; #104160; // Bit 5 = 1
    rx = 1; #104160; // Bit 6 = 0
    rx = 0; #104160; // MSB = 0

    // Stop bit (high)
    rx = 1;
    #104160; // One bit time

    #50000000; // Wait for the data to propagate through the design

    // Press the button to trigger read and write operations
    btn = 1;
    #20 btn = 0;

    // Simulate UART reception of 'B' (ASCII 66, 8'h42)
    // Start bit (low)
    rx = 0;
    #104160; // Wait for one bit time

    // Data bits for 'B' (ASCII 66, binary 01000010)
    rx = 0; #104160; // LSB = 0
    rx = 1; #104160; // Bit 1 = 1
    rx = 1; #104160; // Bit 2 = 0
    rx = 0; #104160; // Bit 3 = 0
    rx = 0; #104160; // Bit 4 = 0
    rx = 0; #104160; // Bit 5 = 1
    rx = 0; #104160; // Bit 6 = 0
    rx = 0; #104160; // MSB = 0

    // Stop bit (high)
    rx = 1;
    #104160; // One bit time

    #500000; // Wait for the data to propagate

    // Press the button again to trigger read and write
    btn = 1;
    #20 btn = 0;

    // Check the display and LEDs
    #1000; // Give time to observe outputs

    // Apply reset
    reset = 1;
    #20 reset = 0;

    // End simulation
    #5000;
    $finish;
end

// Monitor outputs
initial begin
    $monitor("Time: %0t | rx: %b | tx: %b | LED: %h | an: %b | seg: %b", 
             $time, rx, tx, LED, an, seg);
end

endmodule
