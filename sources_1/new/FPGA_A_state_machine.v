module state_machine (
    input clk,                // System clock signal
    input reset,              // Active-high reset
    input [65:0] uart_in,     // Input data from UART (opcode + operands)
    input uart_ready,         // Indicates when UART input is ready
    input [8:0] data,         // Auxiliary data input (possibly for debug or configuration)
    output reg done,          // Flag indicating completion of the selected operation
    output complete,          // Indicates when the I2C transfer is complete
    output ready,             // Indicates when the I2C interface is ready
    inout i2c_sda,            // I2C data line (bidirectional)
    inout wire i2c_scl,       // I2C clock line (bidirectional)
    output [1:0] op,          // Current operation code (extracted from uart_in)
    output [3:0] st,          // Current state indicator (for debugging)
    output [8:0] debugWire    // Debug output signals
);

assign st = state;            // Expose internal state for debugging
assign op = opcode;           // Expose current operation code for debugging/monitoring

// State encoding: defines different stages of operation
parameter IDLE        = 4'b0000;
parameter ASK_TASK    = 4'b0001;
parameter CHOOSE_TASK = 4'b0010;
parameter MULTIPLY    = 4'b0011;
parameter ADD         = 4'b0100;
parameter SUBTRACT    = 4'b0101;
parameter READ_I2C    = 4'b0110; // Not used in current logic, but defined for expansion
parameter WRITE_I2C   = 4'b0111;
parameter DONE_STATE  = 4'b1000;

reg [3:0] state, next_state;   // Registers holding the current and next state
reg [31:0] data_reg;           // Temporary register to hold data if needed (not fully utilized)

// Flags to indicate which operation is chosen
reg add_flag, sub_flag, ready_flag;
wire uart_full_flag; // Flag that might be set by UART logic (not shown here)

// Local parameters and signals for I2C
localparam ack_start = 6'b111111; // Special start pattern for I2C message
reg write; // Control signal to trigger I2C write operations

// Declare wires for arithmetic operations
wire [31:0] A, B, sum, difference;
wire [31:0] final_result;
wire [1:0] opcode;         // Encoded operation chosen from UART input
wire [103:0] output_buff;  // Data buffer to send over I2C (includes ack_start, opcode, operands, result)
wire i2c_done;             // Indicates I2C transaction completed

// UART-related signals (not fully shown)
wire rx_full, rx_empty, btn_tick;

// UART transmission control signals (not fully utilized here)
reg [3:0] char_index;      // Index for UART transmission
reg write_enable;          // Trigger for UART transmission (not fully utilized)

// final_result depends on which flag is set (add or subtract)
assign final_result = (add_flag) ? sum : (sub_flag ? difference : 32'b0);

// Extract opcode and operands A, B from uart_in
assign opcode = uart_in[65:64];    // Top 2 bits: operation code
assign A = uart_in[63:32];         // Next 32 bits: operand A
assign B = uart_in[31:0];          // Last 32 bits: operand B

// Create output buffer: ack pattern + opcode + A + B + final result
assign output_buff = {ack_start, opcode, A, B, final_result};

// Instantiate floating-point adder and subtractor
FP32_CLA_Adder add(.a(A), .b(B), .result(sum));
FP32_CLA_Subtractor subtract(.a(A), .b(B), .result(difference));

// Instantiate I2C master module to send data over I2C
// Note: 'deugWire' appears to be a typo in original code - it should be 'debugWire'
master_i2c master(
    .master_data_in(output_buff),
    .clk(clk),
    .rst(reset),
    .enable(uart_ready),
    .d(data),
    .ready(ready),
    .done(i2c_done),
    .complete(complete),
    .debugWire(debugWire),
    .i2c_sda(i2c_sda),
    .i2c_scl(i2c_scl)
);

// State machine for controlling the flow based on UART input and operation selection
always @(posedge clk or posedge reset) begin
    if (reset) begin
        // On reset, return to IDLE and clear flags
        state <= IDLE;
        done <= 0;
        ready_flag <= 0;
        add_flag = 0;
        sub_flag = 0;
        write = 0;
    end else begin
        state <= next_state; // Move to the next state
    end
end

always @(*) begin
    // Default assignments for control signals each cycle
    next_state = state;
    done = 0;

    case (state)
        IDLE: begin
            // Reset operation flags and wait for next task
            add_flag = 0;
            sub_flag = 0;
            ready_flag <= 0;
            next_state = ASK_TASK;
        end

        ASK_TASK: begin
            // Wait here until UART input is ready
            if (!uart_ready) begin
                // If UART is not ready, keep waiting and set ready_flag
                ready_flag <= 1;
                next_state = ASK_TASK;
            end else begin
                // Once UART is ready, move on to choose the task from the opcode
                next_state = CHOOSE_TASK;
            end
        end

        CHOOSE_TASK: begin
            // Decide next state based on opcode
            case (opcode)
                2'b00: next_state = ADD;
                2'b01: next_state = SUBTRACT;
                2'b10: next_state = MULTIPLY;
                default: next_state = DONE_STATE; // If opcode not recognized, just go to done
            endcase
        end

        MULTIPLY: begin
            // Multiplication case (not fully implemented)
            // Just move on to write the result over I2C
            next_state = WRITE_I2C;
        end

        ADD: begin
            // Set add_flag and then move to write I2C state
            add_flag = 1;
            next_state = WRITE_I2C;
        end

        SUBTRACT: begin
            // Set sub_flag and then move to write I2C state
            sub_flag = 1;
            next_state = WRITE_I2C;
        end

        WRITE_I2C: begin
            // In WRITE_I2C, initiate the I2C operation
            write <= 1;
            // If the I2C transfer completes, move to the done state
            if (complete == 1) begin
                next_state = DONE_STATE;
            end
        end

        DONE_STATE: begin
            // Signal that the entire operation is done
            done = 1;
            write = 1;
            // Return to IDLE to await next command
            next_state = IDLE;
        end

        default: next_state = IDLE; // Default case: go to IDLE if undefined state
    endcase
end

endmodule
