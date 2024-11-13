module state_machine (
    input clk,
    input reset,
    input [65:0] uart_in,
    output reg done,          // flag indicating task completion
    output [15:0] led
);
assign led[15] = ready_flag;
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
wire [1:0] opcode; // Register for task selection

// Flags
reg add_flag, sub_flag, ready_flag;
wire uart_full_flag; // Controlled by UART module

// Outputs to I2C
reg ack_start, ack_end;
wire [31:0] A, B, sum, difference; 
wire [31:0] result;

assign result = (add_flag) ? sum : (sub_flag ? difference : 32'b0);
assign opcode = uart_in[1:0];
assign A = uart_in[33:2];
assign B = uart_in[65:34];
// UART and Debounce Signals
wire rx_full, rx_empty, btn_tick;
// UART Transmission Control
reg [3:0] char_index;               // Index to track the character in the message
reg write_enable;                   // Trigger for UART transmission


FP32_CLA_Adder add(.a(A), .b(B), .result(sum));
FP32_CLA_Subtractor subtract(.a(A), .b(B), .result(difference));

initial begin
    ack_start = 1;
    ack_end = 1;
end

// State machine logic
always @(posedge clk or posedge reset) begin
    if (reset) begin
        state <= IDLE;
        done <= 0;
        ready_flag <= 0;
        add_flag = 0;
        sub_flag = 0;
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
            add_flag = 0;
            sub_flag = 0;
            ready_flag <= 0;
            next_state = ASK_TASK;
        end

        ASK_TASK: begin
             if (!uart_full_flag) begin
                 ready_flag <= 1;
                 next_state = ASK_TASK;
             end else begin
                 next_state = CHOOSE_TASK;
             end
        end

        CHOOSE_TASK: begin
            case (opcode)
                2'b00: next_state = ADD;
                2'b01: next_state = SUBTRACT;
                2'b10: next_state = MULTIPLY;
                default: next_state = DONE_STATE;
            endcase
        end

        MULTIPLY: begin
            next_state = WRITE_I2C;
        end

        ADD: begin
            add_flag = 1;
            next_state = WRITE_I2C;
        end

        SUBTRACT: begin
            sub_flag = 1;
            next_state = WRITE_I2C;
        end

        WRITE_I2C: begin
            // Placeholder for I2C write operation
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
