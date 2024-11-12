module state_machine (
    input clk,
    input reset,
//    input [31:0] uart_data, // 32-bit floating point input from UART
    input [1:0] opcode, // output task selected
    output reg done          // flag indicating task completion
);

// State encoding
parameter IDLE        = 4'b0000;
parameter ASK_TASK    = 4'b0001;
parameter CHOOSE_TASK = 4'b0010;
parameter MULTIPLY    = 4'b0011;
parameter ADD         = 4'b0100;
parameter SUBTRACT    = 4'b0101;
parameter READ_I2C    = 4'b0110;
parameter WRITE_I2C   = 4'b0111;
parameter DONE_STATE  = 4'b1000;

// State and temporary registers
reg [3:0] state, next_state;
reg [31:0] data_reg;

// UART and Debounce Signals
wire rx_full, rx_empty, btn_tick;
// UART Transmission Control
reg [3:0] char_index;               // Index to track the character in the message
reg [7:0] message [0:12];           // Array to store "Enter opcode:" message
reg write_enable;                   // Trigger for UART transmission
// Initialize message with "Enter opcode:" ASCII values
initial begin
    message[0] = 8'h45;   // 'E'
    message[1] = 8'h6E;   // 'n'
    message[2] = 8'h74;   // 't'
    message[3] = 8'h65;   // 'e'
    message[4] = 8'h72;   // 'r'
    message[5] = 8'h20;   // ' ' (space)
    message[6] = 8'h6F;   // 'o'
    message[7] = 8'h70;   // 'p'
    message[8] = 8'h63;   // 'c'
    message[9] = 8'h6F;   // 'o'
    message[10] = 8'h64;  // 'd'
    message[11] = 8'h65;  // 'e'
    message[12] = 8'h3A;  // ':'
end

// State machine logic
always @(posedge clk or posedge reset) begin
    if (reset) begin
        state <= IDLE;
        done <= 0;
//        opcode <= 3'b000;
    end else begin
        state <= next_state;
    end
end

// Next state and output logic
always @(*) begin
    // Default values
    next_state = state;
    done = 0;

    case (state)
        IDLE: begin
//            if (uart_data) // Assuming uart_data signal indicates readiness
                next_state = ASK_TASK;
        end

        ASK_TASK: begin
             char_index = 15;
             if (char_index < 13) begin
                    write_enable = 1;  // Enable writing to UART
                    next_state = ASK_TASK;
                end else if (!rx_empty) begin
                    char_index = 0;    // Reset index after completing message
                    next_state = CHOOSE_TASK;
                end
                next_state = CHOOSE_TASK;
            end

        CHOOSE_TASK: begin
            // Extract opcode (example assumes opcode is in data_reg[2:0])
//            opcode = data_reg[2:0];
            case (opcode)
                0: next_state = ADD;
                1: next_state = SUBTRACT;
                2: next_state = MULTIPLY;

                default: next_state = DONE_STATE;
            endcase
        end

        MULTIPLY: begin
            // Placeholder for multiplication task
            // Perform the operation here
            next_state = DONE_STATE;
        end

        ADD: begin
            // Placeholder for addition task
            // Perform the operation here
            next_state = DONE_STATE;
        end

        SUBTRACT: begin
            // Placeholder for subtraction task
            // Perform the operation here
            next_state = DONE_STATE;
        end

        READ_I2C: begin
            // Placeholder for I2C read operation
            // Perform the read here
            next_state = DONE_STATE;
        end

        WRITE_I2C: begin
            // Placeholder for I2C write operation
            // Perform the write here
            next_state = DONE_STATE;
        end

        DONE_STATE: begin
            done = 1; // Indicate completion
            next_state = IDLE; // Go back to idle
        end

        default: next_state = IDLE;
    endcase
end

endmodule


`timescale 1ns / 1ps

module uart_floating_point_interface
    #(
        parameter DBITS = 8,          // Number of data bits in UART communication
                  SB_TICK = 16,       // Number of stop bit ticks
                  BR_LIMIT = 651,     // Baud rate generator counter limit
                  BR_BITS = 10,       // Number of baud rate generator counter bits
                  FIFO_EXP = 4        // Exponent for FIFO size (2^FIFO_EXP)
    )
    (
        input clk_100MHz,
        input reset,
        input rx,                     // UART receive line
        output tx,                    // UART transmit line
        output reg [31:0] A,          // First 32-bit floating-point number
        output reg [31:0] B           // Second 32-bit floating-point number
    );

    // Internal signals
    wire tick;
    wire rx_done_tick;
    wire tx_done_tick;
    wire [7:0] rx_data_out;
    reg [1:0] state;
    reg [5:0] bit_counter;
    reg [31:0] input_buffer;

    // Transmission logic
    reg [7:0] tx_buffer;            // Current byte to transmit
    reg tx_start;                   // Signal to start transmission
    reg [3:0] tx_state;             // Transmission state
    reg [7:0] tx_message_a [0:11];  // "A received" + newline
    reg [7:0] tx_message_b [0:11];  // "B received" + newline
    integer tx_index;               // Index for message transmission

    // State encoding for reception
    localparam IDLE     = 2'b00;
    localparam READ_A   = 2'b01;
    localparam READ_B   = 2'b10;
    localparam PROCESS  = 2'b11;

    // State encoding for transmission
    localparam TX_IDLE      = 4'd0;
    localparam TX_SEND_A    = 4'd1;
    localparam TX_SEND_A_BYTE = 4'd2;
    localparam TX_WAIT_A_DONE = 4'd3;
    localparam TX_SEND_B    = 4'd4;
    localparam TX_SEND_B_BYTE = 4'd5;
    localparam TX_WAIT_B_DONE = 4'd6;

    // Initialize transmission messages
    initial begin
        // "A received\n"
        tx_message_a[0]  = "A";
        tx_message_a[1]  = " ";
        tx_message_a[2]  = "r";
        tx_message_a[3]  = "e";
        tx_message_a[4]  = "c";
        tx_message_a[5]  = "e";
        tx_message_a[6]  = "i";
        tx_message_a[7]  = "v";
        tx_message_a[8]  = "e";
        tx_message_a[9]  = "d";
        tx_message_a[10] = "\n";
        tx_message_a[11] = 8'd0; // Null terminator or unused

        // "B received\n"
        tx_message_b[0]  = "B";
        tx_message_b[1]  = " ";
        tx_message_b[2]  = "r";
        tx_message_b[3]  = "e";
        tx_message_b[4]  = "c";
        tx_message_b[5]  = "e";
        tx_message_b[6]  = "i";
        tx_message_b[7]  = "v";
        tx_message_b[8]  = "e";
        tx_message_b[9]  = "d";
        tx_message_b[10] = "\n";
        tx_message_b[11] = 8'd0; // Null terminator or unused
    end

    // Instantiate UART modules
    baud_rate_generator 
        #(
            .M(BR_LIMIT), 
            .N(BR_BITS)
        ) 
        baud_gen (
            .clk_100MHz(clk_100MHz), 
            .reset(reset),
            .tick(tick)
        );

    uart_receiver
        #(
            .DBITS(DBITS),
            .SB_TICK(SB_TICK)
        )
        uart_rx (
            .clk_100MHz(clk_100MHz),
            .reset(reset),
            .rx(rx),
            .sample_tick(tick),
            .data_ready(rx_done_tick),
            .data_out(rx_data_out)
        );

    uart_transmitter
        #(
            .DBITS(DBITS),
            .SB_TICK(SB_TICK)
        )
        uart_tx (
            .clk_100MHz(clk_100MHz),
            .reset(reset),
            .tx_start(tx_start),
            .sample_tick(tick),
            .data_in(tx_buffer),
            .tx_done(tx_done_tick),
            .tx(tx)
        );

    // Main state machine to receive two 32-bit floating-point numbers and send messages
    always @(posedge clk_100MHz or posedge reset) begin
        if (reset) begin
            state <= IDLE;
            bit_counter <= 6'd0;
            input_buffer <= 32'd0;
            A <= 32'd0;
            B <= 32'd0;
            // Transmission variables
            tx_state <= TX_IDLE;
            tx_index <= 0;
            tx_start <= 0;
            tx_buffer <= 8'd0;
        end else begin
            case (state)
                IDLE: begin
                    // Initial state, ready to read A
                    state <= READ_A;
                end

                READ_A: begin
                    if (rx_done_tick) begin
                        input_buffer <= {input_buffer[23:0], rx_data_out};
                        bit_counter <= bit_counter + 6'd8;
                        if (bit_counter == 6'd24) begin
                            A <= {input_buffer[23:0], rx_data_out};
                            input_buffer <= 32'd0;
                            bit_counter <= 6'd0;
                            state <= TX_SEND_A; // Transition to send message after A is read
                        end
                    end
                end

                READ_B: begin
                    if (rx_done_tick) begin
                        input_buffer <= {input_buffer[23:0], rx_data_out};
                        bit_counter <= bit_counter + 6'd8;
                        if (bit_counter == 6'd24) begin
                            B <= {input_buffer[23:0], rx_data_out};
                            input_buffer <= 32'd0;
                            bit_counter <= 6'd0;
                            state <= TX_SEND_B; // Transition to send message after B is read
                        end
                    end
                end

                PROCESS: begin
                    // Placeholder for processing A and B
                    // After processing, you can transition to IDLE or another state
                    state <= IDLE;
                end

                default: state <= IDLE;
            endcase

            // Transmission state machine
            case (tx_state)
                TX_IDLE: begin
                    // Wait for transmission requests
                    // Do nothing
                end

                TX_SEND_A: begin
                    // Start sending "A received"
                    tx_index <= 0;
                    tx_buffer <= tx_message_a[tx_index];
                    tx_start <= 1;
                    tx_state <= TX_SEND_A_BYTE;
                end

                TX_SEND_A_BYTE: begin
                    if (tx_done_tick) begin
                        tx_start <= 0;
                        tx_index <= tx_index + 1;
                        if (tx_message_a[tx_index] != 8'd0) begin
                            tx_buffer <= tx_message_a[tx_index];
                            tx_start <= 1;
                            tx_state <= TX_SEND_A_BYTE;
                        end else begin
                            tx_state <= READ_B; // After sending, proceed to read B
                        end
                    end
                end

                TX_SEND_B: begin
                    // Start sending "B received"
                    tx_index <= 0;
                    tx_buffer <= tx_message_b[tx_index];
                    tx_start <= 1;
                    tx_state <= TX_SEND_B_BYTE;
                end

                TX_SEND_B_BYTE: begin
                    if (tx_done_tick) begin
                        tx_start <= 0;
                        tx_index <= tx_index + 1;
                        if (tx_message_b[tx_index] != 8'd0) begin
                            tx_buffer <= tx_message_b[tx_index];
                            tx_start <= 1;
                            tx_state <= TX_SEND_B_BYTE;
                        end else begin
                            tx_state <= PROCESS; // After sending, proceed to processing
                        end
                    end
                end

                default: tx_state <= TX_IDLE;
            endcase
        end
    end

    // Transition to READ_B after sending "A received"
    always @(posedge clk_100MHz or posedge reset) begin
        if (reset) begin
            // Nothing to do
        end else begin
            if (state == TX_SEND_A_BYTE && tx_done_tick && tx_index == 11) begin
                state <= READ_B;
            end
        end
    end

    // Additional logic to handle READ_B transition
    // Modified the main state machine to include sending messages

endmodule
