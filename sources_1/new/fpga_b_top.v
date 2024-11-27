`timescale 1ns / 1ps

module fpga_b_top(
    input clk,
    input rst,
    inout wire sda,
    input wire scl,
    output CS,
    output SDIN,
    output SCLK,
    output DC,
    output RES,
    output VBAT,
    output VDD,
    output FIN
    // for testbench
    // output [7:0] received_data,
    // output [103:0] i2c_in,
    // output ready
);

localparam IDLE = 3'b000;
localparam RECEIVING = 3'b001;
localparam WAIT_LOW = 3'b010;
localparam PROCESS = 3'b011;
localparam UPDATE_DISPLAY = 3'b100;
localparam WAIT_NEXT = 3'b101;

reg [2:0] current_state, next_state;
reg [3:0] byte_counter;
reg [1:0] opcode;
reg transmission_complete;
reg [103:0] i2c_buffer;
reg [103:0] i2c_last_complete_transmission;
reg ready_reg;
reg byte_stored;

wire [3:0] debug_oled_fifo_wptr;
wire [3:0] debug_old_fifo_rptr;
wire clk_1Hz;
wire multiplied_valid;
wire [31:0] product;
reg [31:0] ans;

// reg [127:0] line0_reg, line1_reg, line2_reg, line3_reg;
wire [127:0] line0_reg, line1_reg, line2_reg, line3_reg;
wire new_byte_received;
wire [7:0] received_data;
wire i2c_ack;

reg [31:0] mult_a;
reg [31:0] mult_b;


i2c_slave_controller i2c_slave(
    .sda(sda),
    .scl(scl),
    .ack(i2c_ack),
    .new_byte_received(new_byte_received),
    .data_out(received_data),
    .slave_addr(7'b0000111)
);

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

multiplier MULT(
    .clk(clk),
    .rst(rst),
    .a(mult_a),
    .b(mult_b),
    .result(product),
    .valid(multiplied_valid)
);

clock_divider ClockDivider(
    .clk_100MHz(clk),
    .reset(rst),
    .clk_1Hz(clk_1Hz)
);

function [7:0] bin_to_ascii_hex;
    input [3:0] bin;
    begin
        case (bin)
            4'b0000: bin_to_ascii_hex = 8'h30; // '0'
            4'b0001: bin_to_ascii_hex = 8'h31; // '1'
            4'b0010: bin_to_ascii_hex = 8'h32; // '2'
            4'b0011: bin_to_ascii_hex = 8'h33; // '3'
            4'b0100: bin_to_ascii_hex = 8'h34; // '4'
            4'b0101: bin_to_ascii_hex = 8'h35; // '5'
            4'b0110: bin_to_ascii_hex = 8'h36; // '6'
            4'b0111: bin_to_ascii_hex = 8'h37; // '7'
            4'b1000: bin_to_ascii_hex = 8'h38; // '8'
            4'b1001: bin_to_ascii_hex = 8'h39; // '9'
            4'b1010: bin_to_ascii_hex = 8'h41; // 'A'
            4'b1011: bin_to_ascii_hex = 8'h42; // 'B'
            4'b1100: bin_to_ascii_hex = 8'h43; // 'C'
            4'b1101: bin_to_ascii_hex = 8'h44; // 'D'
            4'b1110: bin_to_ascii_hex = 8'h45; // 'E'
            4'b1111: bin_to_ascii_hex = 8'h46; // 'F'
            default: bin_to_ascii_hex = 8'h2A; // '*'
        endcase
    end
endfunction

function [63:0] large_bin_to_ascii_hex;
    input [31:0] bin;
    begin
        large_bin_to_ascii_hex = {
            bin_to_ascii_hex(bin[31:28]),
            bin_to_ascii_hex(bin[27:24]),
            bin_to_ascii_hex(bin[23:20]),
            bin_to_ascii_hex(bin[19:16]),
            bin_to_ascii_hex(bin[15:12]),
            bin_to_ascii_hex(bin[11:8]),
            bin_to_ascii_hex(bin[7:4]),
            bin_to_ascii_hex(bin[3:0])
        };
    end
endfunction

assign line0_reg = {32'h4F504344, 32'h3A200000, large_bin_to_ascii_hex({30'h000, opcode})};  // "OPCD: x"
assign line1_reg = {32'h413A2000, 32'h20000000, large_bin_to_ascii_hex(mult_a)};              // "A: xxx"
assign line2_reg = {32'h423A2000, 32'h20000000, large_bin_to_ascii_hex(mult_b)};              // "B: xxx"
assign line3_reg = {32'h414E533A, 32'h20000000, large_bin_to_ascii_hex(opcode == 2'b10 ? product : ans)};             // "ANS: xxx"



// sequential logic
always @(posedge clk or posedge rst) begin
    if (rst) begin
        current_state <= IDLE;
        byte_counter <= 4'd0;
        i2c_buffer <= 104'd0;
        i2c_last_complete_transmission <= 104'd0;
        // transmission_complete <= 1'b0;
        ready_reg <= 1'b0;
        byte_stored <= 1'b0;


        // for testing
        opcode <= 2'b10;
        mult_a <= 32'h40000000;
        mult_b <= 32'h40000000;
        // ans <= 32'h40800000;
        // end testing
        // assign line0_reg = {32'h4F504344, 32'h3A200000, large_bin_to_ascii_hex({30'h000, opcode})};  // "OPCD: x"
        // assign line1_reg = {32'h413A2000, 32'h20000000, large_bin_to_ascii_hex(mult_a)};              // "A: xxx"
        // assign line2_reg = {32'h423A2000, 32'h20000000, large_bin_to_ascii_hex(mult_b)};              // "B: xxx"
        // assign line3_reg = {32'h414E533A, 32'h20000000, large_bin_to_ascii_hex(product)};             // "ANS: xxx"
    end else begin
        current_state <= next_state;
        
        case (current_state)
            IDLE: begin
                if (new_byte_received && !byte_stored) begin
                    if (received_data[7:2] == 6'b111111) begin
                        transmission_complete <= 1'b0;
                        byte_counter <= 4'd1;
                        opcode <= received_data[1:0];
                        i2c_buffer[103:96] <= received_data;
                        byte_stored <= 1'b1;
                    end
                end
            end
            
            RECEIVING: begin
                if (new_byte_received && !byte_stored) begin
                    case (byte_counter)
                        4'd1: i2c_buffer[95:88] <= received_data;
                        4'd2: i2c_buffer[87:80] <= received_data;
                        4'd3: i2c_buffer[79:72] <= received_data;
                        4'd4: i2c_buffer[71:64] <= received_data;
                        4'd5: i2c_buffer[63:56] <= received_data;
                        4'd6: i2c_buffer[55:48] <= received_data;
                        4'd7: i2c_buffer[47:40] <= received_data;
                        4'd8: i2c_buffer[39:32] <= received_data;
                        4'd9: i2c_buffer[31:24] <= received_data;
                        4'd10: i2c_buffer[23:16] <= received_data;
                        4'd11: i2c_buffer[15:8] <= received_data;
                        4'd12: begin
                            i2c_buffer[7:0] <= received_data;
                            transmission_complete <= 1'b1;
                        end
                    endcase
                    
                    if (byte_counter < 4'd12)
                        byte_counter <= byte_counter + 1;
                    byte_stored <= 1'b1;
                end
            end
            
            WAIT_LOW: begin
                if (!new_byte_received) begin
                    byte_stored <= 1'b0;
                end
            end
            
            PROCESS: begin
                mult_a <= i2c_buffer[95:64];  // operand a
                mult_b <= i2c_buffer[63:32];  // operand b
                // if (opcode == 2'b10) begin
                //     // handled with posedge mul_valid
                //     if (multiplied_valid)
                //         ans <= product;
                // end else begin
                //     ans <= i2c_buffer[31:0];  // provided ans
                // end
                ready_reg <= 1'b1;
            end
            
            UPDATE_DISPLAY: begin
                // Update OLED, bin_to_ascii_hex(tx_data[7:4])
                // line0_reg <= {32'h4F504344, 32'h3A200000, large_bin_to_ascii_hex({30'h000, opcode})};  // "OPCD: x"
                // line1_reg <= {32'h413A2000, 32'h20000000, large_bin_to_ascii_hex(mult_a)};              // "A: xxx"
                // line2_reg <= {32'h423A2000, 32'h20000000, large_bin_to_ascii_hex(mult_b)};              // "B: xxx"
                // line3_reg <= {32'h414E533A, 32'h20000000, large_bin_to_ascii_hex(ans)};             // "ANS: xxx"
            end
            
            WAIT_NEXT: begin
                // transmission_complete <= 1'b0;
                ready_reg <= 1'b0;
                byte_counter <= 4'd0;
                byte_stored <= 1'b0;
            end
        endcase
    end
end

// always @(posedge multiplied_valid) begin
//     if(opcode == 2'b10) begin
//         // ans <= product;
//         line3_reg <= {32'h414E533A, 32'h20000000, large_bin_to_ascii_hex(ans)}; 
//     end

// end
// combinational logic
always @(*) begin
    next_state = current_state;
    
    case (current_state)
        IDLE: begin
            if (new_byte_received && !byte_stored && received_data[7:2] == 6'b111111)
                next_state = WAIT_LOW;
        end
        
        RECEIVING: begin
            if (transmission_complete)
                next_state = PROCESS;
            else if (new_byte_received && !byte_stored)
                next_state = WAIT_LOW;
        end
        
        WAIT_LOW: begin
            if (!new_byte_received) begin
                if (transmission_complete)
                    next_state = PROCESS;
                else
                    next_state = RECEIVING;
            end
        end
        
        PROCESS: begin
            if ((opcode != 2'b10) || (opcode == 2'b10 && multiplied_valid))
                next_state = UPDATE_DISPLAY;
        end
        
        UPDATE_DISPLAY: begin
            next_state = WAIT_NEXT;
        end
        
        WAIT_NEXT: begin
            next_state = IDLE;
        end
    endcase
end

assign ready = ready_reg;
assign i2c_in = i2c_buffer;

endmodule











// FOR INDIVIDUAL INPUT TESTING WITH input [103:0] i2c_in
// `timescale 1ns / 1ps

// module fpga_b_top(
//     input clk,
//     input rst,
//     input [103:0] i2c_in,
// //    inout wire sda,
// //    inout wire scl,
// //    input [1:0] mode,
//     output CS,
//     output SDIN,
//     output SCLK,
//     output DC,
//     output RES,
//     output VBAT,
//     output VDD,
//     output FIN
// );

// wire [3:0] debug_oled_fifo_wptr;
// wire [3:0] debug_old_fifo_rptr;

// wire clk_1Hz;
// reg en;
// wire multiplied_valid;
// wire [31:0] product;

// reg [31:0] mult_a;
// reg [31:0] mult_b;
// reg [127:0] line0_reg, line1_reg, line2_reg, line3_reg;


// reg [7:0] slave_addr = 7'b0000111;

// PmodOLEDCtrl OLED(
//     .CLK(clk),
//     .RST(rst),
//     .EN(clk_1Hz),
//     .SW(4'b1111),
//     .CS(CS),
//     .SDIN(SDIN),
//     .SCLK(SCLK),
//     .DC(DC),
//     .RES(RES),
//     .VBAT(VBAT),
//     .VDD(VDD),
//     .FIN(FIN),
//     .rx_irq(1'b0),
//     .tx_irq(1'b0),
//     .rx_data(8'b0),
//     .reg0(line0_reg),
//     .reg1(line1_reg),
//     .reg2(line2_reg),
//     .reg3(line3_reg),
//     .write_pointer(debug_oled_fifo_wptr),
//     .read_pointer(debug_old_fifo_rptr)
// );

// clock_divider ClockDivider(
//     .clk_100MHz(clk),
//     .reset(rst),
//     .clk_1Hz(clk_1Hz)
// );

// multiplier MULT(
//     .clk(clk),
//     .rst(rst),
//     .a(mult_a),
//     .b(mult_b),
//     .result(product),
//     .valid(multiplied_valid)
// );

// localparam IDLE = 2'b00;
// localparam MULTIPLY = 2'b01;
// localparam UPDATE_OLED = 2'b10;

// wire [31:0] operand_a = i2c_in[95:64];
// wire [31:0] operand_b = i2c_in[63:32];
// wire [31:0] ans = i2c_in[31:0];
// wire [1:0] operation = i2c_in[103:96];

// reg [1:0] current_state;
// reg [1:0] next_state;


// always @(posedge clk or posedge rst) begin
//     if (rst) begin
//         current_state <= IDLE;
//         mult_a <= 32'h0;
//         mult_b <= 32'h0;
//     end else begin
//         current_state <= next_state;
        
//         // Handle multiplier input updates in sequential block
//         if (current_state == IDLE && operation == 2'b10) begin
//             mult_a <= operand_a;
//             mult_b <= operand_b;
//         end
//     end
// end

// // State machine combinational logic
// always @(*) begin
//     next_state = current_state;
    
//     case (current_state)
//         IDLE: begin
//             if (operation == 2'b10) begin
//                 next_state = MULTIPLY;
//             end else if (operation == 2'b00 || operation == 2'b01) begin
//                 next_state = UPDATE_OLED;
//             end
//         end
        
//         MULTIPLY: begin
//             if (multiplied_valid) begin
//                 next_state = UPDATE_OLED;
//             end
//         end
        
//         UPDATE_OLED: begin
//             next_state = IDLE;
//         end
        
//         default: next_state = IDLE;
//     endcase
// end

// // Output logic
// always @(posedge clk or posedge rst) begin
//     if (rst) begin
//         line0_reg <= 128'h0;
//         line1_reg <= 128'h0;
//         line2_reg <= 128'h0;
//         line3_reg <= 128'h0;
//         // line3_reg <= 128'h454D50545920464C4147000000000000;
//         en <= 1'b0;
//     end else begin
//         case (current_state)
//             IDLE: begin
//                 en <= 1'b0;
//             end
            
//             MULTIPLY: begin
//                 if (multiplied_valid) begin
//                     line0_reg <= {96'h0, product};
//                     en <= 1'b1;
//                 end
//             end
            
//             UPDATE_OLED: begin
//                 case (operation)
//                     2'b00: begin
//                         line0_reg <= {96'h0, ans};
//                         line1_reg <= 128'h4F5000414444;  // OP ADD
//                     end
//                     2'b01: begin
//                         line0_reg <= {96'h0, ans};
//                         line1_reg <= 128'h4F5000535542;  // OP SUB
//                     end
//                     2'b10: begin
//                         line0_reg <= {96'h0, product};
//                         line1_reg <= 128'h4F50004D554C;  // OP MUL
//                     end
//                     2'b11: begin
//                         line0_reg <= {96'h0, product};
//                         line1_reg <= 128'h4F5000444956;  // OP DIV
//                     end

//                 endcase
//                 en <= 1'b1;
//             end
            
//             default: begin
//                 en <= 1'b0;
//             end
//         endcase
//     end
// end

// endmodule