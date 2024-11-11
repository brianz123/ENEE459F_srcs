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
