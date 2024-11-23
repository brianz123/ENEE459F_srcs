`timescale 1ns / 1ps

module fpga_b_top(
    input clk,
    input rst,
    input [65:0] uart_in,
    input [31:0] ans,
//    inout wire sda,
//    inout wire scl,
//    input [1:0] mode,
    output CS,
    output SDIN,
    output SCLK,
    output DC,
    output RES,
    output VBAT,
    output VDD,
    output FIN
);

wire [3:0] debug_oled_fifo_wptr;
wire [3:0] debug_old_fifo_rptr;

wire clk_1Hz;
reg en;
wire multiplied_valid;
wire [31:0] product;


//reg [31:0] ans;
//wire [65:0] uart_in = {mode, ans, ans};

reg [31:0] mult_a;
reg [31:0] mult_b;
reg [127:0] line0_reg, line1_reg, line2_reg, line3_reg;

PmodOLEDCtrl OLED(
    .CLK(clk),
    .RST(rst),
    .EN(clk_1Hz),
    .SW(4'b1111),
    .CS(CS),
    .SDIN(SDIN),
    .SCLK(SCLK),
    .DC(DC),
    .RES(RES),
    .VBAT(VBAT),
    .VDD(VDD),
    .FIN(FIN),
    .rx_irq(1'b0),
    .tx_irq(1'b0),
    .rx_data(8'b0),
    .reg0(line0_reg),
    .reg1(line1_reg),
    .reg2(line2_reg),
    .reg3(line3_reg),
    .write_pointer(debug_oled_fifo_wptr),
    .read_pointer(debug_old_fifo_rptr)
);

clock_divider ClockDivider(
    .clk_100MHz(clk),
    .reset(rst),
    .clk_1Hz(clk_1Hz)
);

multiplier MULT(
    .clk(clk),
    .rst(rst),
    .a(mult_a),
    .b(mult_b),
    .result(product),
    .valid(multiplied_valid)
);

localparam IDLE = 2'b00;
localparam MULTIPLY = 2'b01;
localparam UPDATE_OLED = 2'b10;

wire [31:0] operand_a = uart_in[31:0];
wire [31:0] operand_b = uart_in[63:32];
wire [1:0] operation = uart_in[65:64];

reg [1:0] current_state;
reg [1:0] next_state;


always @(posedge clk or posedge rst) begin
    if (rst) begin
        current_state <= IDLE;
        mult_a <= 32'h0;
        mult_b <= 32'h0;
    end else begin
        current_state <= next_state;
        
        // Handle multiplier input updates in sequential block
        if (current_state == IDLE && operation == 2'b10) begin
            mult_a <= operand_a;
            mult_b <= operand_b;
        end
    end
end

// State machine combinational logic
always @(*) begin
    next_state = current_state;
    
    case (current_state)
        IDLE: begin
            if (operation == 2'b10) begin
                next_state = MULTIPLY;
            end else if (operation == 2'b00 || operation == 2'b01) begin
                next_state = UPDATE_OLED;
            end
        end
        
        MULTIPLY: begin
            if (multiplied_valid) begin
                next_state = UPDATE_OLED;
            end
        end
        
        UPDATE_OLED: begin
            next_state = IDLE;
        end
        
        default: next_state = IDLE;
    endcase
end

// Output logic
always @(posedge clk or posedge rst) begin
    if (rst) begin
        line0_reg <= 128'h0;
        line1_reg <= 128'h0;
        line2_reg <= 128'h0;
        line3_reg <= 128'h0;
        // line3_reg <= 128'h454D50545920464C4147000000000000;
        en <= 1'b0;
    end else begin
        case (current_state)
            IDLE: begin
                en <= 1'b0;
            end
            
            MULTIPLY: begin
                if (multiplied_valid) begin
                    line0_reg <= {96'h0, product};
                    en <= 1'b1;
                end
            end
            
            UPDATE_OLED: begin
                case (operation)
                    2'b00: begin
                        line0_reg <= {96'h0, ans};
                        line1_reg <= 128'h4F5000414444;  // OP ADD
                    end
                    2'b01: begin
                        line0_reg <= {96'h0, ans};
                        line1_reg <= 128'h4F5000535542;  // OP SUB
                    end
                    2'b10: begin
                        line0_reg <= {96'h0, product};
                        line1_reg <= 128'h4F50004D554C;  // OP MUL
                    end
                    2'b11: begin
                        line0_reg <= {96'h0, product};
                        line1_reg <= 128'h4F5000444956;  // OP DIV
                    end

                endcase
                en <= 1'b1;
            end
            
            default: begin
                en <= 1'b0;
            end
        endcase
    end
end

endmodule