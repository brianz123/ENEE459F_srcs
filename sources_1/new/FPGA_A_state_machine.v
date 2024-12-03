module state_machine (
    input clk,
    input reset,
    input [65:0] uart_in,
    input uart_ready,
    output reg done,          // Flag indicating task completion
//    output [15:0] led,
    output complete,
    output ready,
//    output done,
    inout i2c_sda,
	inout wire i2c_scl,
	output [1:0] op,
    output [3:0] st,
    output [8:0] debugWire
   
	
);
assign st = state;
assign op = opcode;
    // Assignments
//    assign led[15] = ready_flag;

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

    // Flags
    reg add_flag, sub_flag, ready_flag;
    wire uart_full_flag; // Controlled by UART module

    // Outputs to I2C
    localparam ack_start = 6'b111111;
    reg write;
//    wire ready;
    
    
    // Data wires
    wire [31:0] A, B, sum, difference; 
    wire [31:0] final_result;
    wire [1:0] opcode; // Register for task selection
    wire [103:0] output_buff;
    wire i2c_done;
    // UART and debounce signals
    wire rx_full, rx_empty, btn_tick;

    // UART transmission control
    reg [3:0] char_index;               // Index to track the character in the message
    reg write_enable;                   // Trigger for UART transmission
    
    // Assignments
    assign final_result = (add_flag) ? sum : (sub_flag ? difference : 32'b0);
    assign opcode = uart_in[65:64];
    assign A = uart_in[63:32];
    assign B = uart_in[31:0];
    assign output_buff = {ack_start, opcode, A, B, final_result};

    // Floating-point add/subtract modules
    FP32_CLA_Adder add(.a(A), .b(B), .result(sum));
    FP32_CLA_Subtractor subtract(.a(A), .b(B), .result(difference));

    master_i2c master(
        .master_data_in(output_buff),
        .clk(clk),
        .rst(reset),
        .enable(uart_ready),
        .ready(ready),
        .done(i2c_done),
        .complete(complete),
        .debugWire(deugWire),
        .i2c_sda(i2c_sda),
        .i2c_scl(i2c_scl)
    );
    
  

    // State machine logic
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            state <= IDLE;
            done <= 0;
            ready_flag <= 0;
            add_flag = 0;
            sub_flag = 0;
            write = 0;
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
                if (!uart_ready) begin
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
                write <=1;
                if(complete == 1)begin
                    next_state = DONE_STATE;
                end
            end

            DONE_STATE: begin
                done = 1; // Indicate completion
                write =1;
                next_state = IDLE; // Go back to idle
            end

            default: next_state = IDLE;
        endcase
    end

endmodule
