`timescale 1ns / 1ps

module uart_floating_point_interface_tb;
    reg clk_100MHz;
    reg reset;
    reg rx;
    wire tx;
    wire [31:0] A;
    wire [31:0] B;

    // Instantiate the module
    uart_floating_point_interface uut (
        .clk_100MHz(clk_100MHz),
        .reset(reset),
        .rx(rx),
        .tx(tx),
        .A(A),
        .B(B)
    );

    // Clock generation
    initial begin
        clk_100MHz = 0;
        forever #5 clk_100MHz = ~clk_100MHz;  // 100MHz clock
    end

    // UART parameters
    parameter BIT_PERIOD = 104160;  // For 9600 baud rate (in ns)

    // Variables to capture transmitted messages
    reg [7:0] received_tx_data;
    integer tx_byte_count;
    integer tx_capture_finished;

    // Test sequence
    initial begin
        // Initialize inputs
        reset = 1;
        rx = 1;  // UART idle state

        // Initialize transmission capture variables
        tx_byte_count = 0;
        tx_capture_finished = 0;

        #100;
        reset = 0;

        #1000;

        // Simulate sending 32-bit float A (e.g., 1.5 in IEEE 754)
        send_float_via_uart(32'h3FC00000);  // 1.5 in IEEE 754

        #100000;

        // Simulate sending 32-bit float B (e.g., -2.25 in IEEE 754)
        send_float_via_uart(32'hC0080000);  // -2.25 in IEEE 754

        #200000;

        // At this point, messages "A received\n" and "B received\n" should have been sent
        $display("A = %h", A);
        $display("B = %h", B);

        #100000;
        $stop;
    end

    // Capture transmitted data
    always @(posedge clk_100MHz) begin
        if (tx_byte_count < 12 && !tx_capture_finished) begin
            if (uut.tx_start && uut.tx_done_tick) begin
                received_tx_data = uut.tx_buffer;
                $write("%c", received_tx_data);  // Print the transmitted character
                tx_byte_count = tx_byte_count + 1;
                if (tx_byte_count == 11) begin
                    tx_capture_finished = 1;
                end
            end
        end
    end

    // Task to send a 32-bit float via UART
    task send_float_via_uart;
        input [31:0] float_data;
        integer i;
        reg [7:0] byte_data;
        begin
            // Send most significant byte first (big-endian)
            for (i = 3; i >= 0; i = i - 1) begin
                byte_data = float_data[i*8 +: 8];
                send_byte(byte_data);
            end
        end
    endtask

    // Task to send a byte via UART
    task send_byte;
        input [7:0] data;
        integer i;
        begin
            // Start bit
            rx = 0;
            #(BIT_PERIOD);

            // Data bits (LSB first)
            for (i = 0; i < 8; i = i + 1) begin
                rx = data[i];
                #(BIT_PERIOD);
            end

            // Stop bit
            rx = 1;
            #(BIT_PERIOD);
        end
    endtask
endmodule
