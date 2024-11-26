module multiplier (
    input wire clk,
    input wire rst,
    input wire [31:0] a,
    input wire [31:0] b,
    output reg [31:0] result,
    output reg valid
);

    reg sign_a, sign_b, sign_result;
    reg [7:0] exp_a, exp_b, exp_result;
    reg [22:0] mantissa_a, mantissa_b;
    reg [47:0] mantissa_result;
    wire [47:0] product_mantissa;
    reg [8:0] temp_exp;  // 9 bits to handle overflow
    
    integer i;
    
    // hidden bit (1.mantissa)
    wire [23:0] mantissa_a_complete = {1'b1, mantissa_a};
    wire [23:0] mantissa_b_complete = {1'b1, mantissa_b};
    
    // reg [24:0] booth_encoded[11:0];
    // reg [2:0] booth_sel[11:0];
    reg [25:0] temp_b;

    reg [47:0] wallace_sum;
    reg [47:0] wallace_carry;
    
    localparam BIAS = 8'd127;

    localparam IDLE = 3'd0;
    localparam DECODE = 3'd1;
    localparam MULTIPLY = 3'd2;
    localparam NORMALIZE = 3'd3;
    localparam ROUND = 3'd4;
    
    reg [2:0] state;

    wallace_booth_multiplier_24bit multiplier_instance (
        .multiplicand(mantissa_a_complete),
        .multiplier(mantissa_a_complete),
        .product(product_mantissa)
    );
    
    // // Booth Radix-4 Encoding Function
    // function [24:0] booth_encode;
    //     input [2:0] sel;
    //     input [23:0] multiplicand;
    //     begin
    //         case(sel)
    //             3'b000: booth_encode = 25'd0;
    //             3'b001: booth_encode = {multiplicand, 1'b0};
    //             3'b010: booth_encode = {multiplicand, 1'b0};
    //             3'b011: booth_encode = {multiplicand, 1'b0} << 1;
    //             3'b100: booth_encode = ~({multiplicand, 1'b0} << 1) + 1;
    //             3'b101: booth_encode = ~{multiplicand, 1'b0} + 1;
    //             3'b110: booth_encode = ~{multiplicand, 1'b0} + 1;
    //             3'b111: booth_encode = 25'd0;
    //         endcase
    //     end
    // endfunction
    
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            state <= IDLE;
            valid <= 1'b0;
            result <= 32'd0;
            mantissa_result <= 48'd0;
            // product_mantissa <= 48'd0;
            temp_exp <= 9'd0;
            temp_b <= 26'd0;
            
            // for (i = 0; i < 12; i = i + 1) begin
            //     booth_encoded[i] <= 25'd0;
            //     booth_sel[i] <= 3'd0;
            // end
        end
        else begin
            case (state)
                IDLE: begin
                    // extract components
                    sign_a <= a[31];
                    sign_b <= b[31];
                    exp_a <= a[30:23];
                    exp_b <= b[30:23];
                    mantissa_a <= a[22:0];
                    mantissa_b <= b[22:0];
                    valid <= 1'b0;
                    state <= DECODE;
                end
                
                DECODE: begin
                    // handle special cases
                    if (exp_a == 8'd0 || exp_b == 8'd0) begin
                        // Zero result
                        result <= {sign_a ^ sign_b, 31'd0};
                        state <= IDLE;
                        valid <= 1'b1;
                    end
                    else if (exp_a == 8'hFF || exp_b == 8'hFF) begin
                        // infinity or NaN
                        result <= {sign_a ^ sign_b, 8'hFF, 23'd0};
                        state <= IDLE;
                        valid <= 1'b1;
                    end
                    else begin
                        // prepare for multiplication
                        temp_b <= {mantissa_b_complete, 2'b0};
                        state <= MULTIPLY;
                    end
                end
                
                MULTIPLY: begin
                    // ONLY FOR TESTING
                    // product_mantissa <= mantissa_a_complete * mantissa_b_complete;
                    // MULTIPLCATION done by booth_multiplier_24bit multiplier_instance
                    
                    temp_exp <= exp_a + exp_b - BIAS;
                    state <= NORMALIZE;
                end
                
                NORMALIZE: begin
                    // Normalize the result
                    if (product_mantissa[47]) begin
                        // Result needs right shift
                        mantissa_result <= product_mantissa >> 1;
                        temp_exp <= temp_exp + 1;
                    end
                    else if (!product_mantissa[46]) begin
                        // Result needs left shift
                        mantissa_result <= product_mantissa << 1;
                        temp_exp <= temp_exp - 1;
                    end
                    else begin
                        mantissa_result <= product_mantissa;
                    end
                    
                    sign_result <= sign_a ^ sign_b;
                    state <= ROUND;
                end
                
                ROUND: begin
                    // round towards positive infinity
                    if (|mantissa_result[23:0]) begin  // if there are any bits after the rounding position
                        if (mantissa_result[46:24] == 23'h7FFFFF) begin
                            // rounding causes overflow
                            mantissa_result <= {48'h8000000000000};
                            temp_exp <= temp_exp + 1;
                        end
                        else begin
                            mantissa_result[46:24] <= mantissa_result[46:24] + 1;
                        end
                    end
                    
                    // check for exponent overflow/underflow
                    if (temp_exp[8] || temp_exp[7:0] == 8'hFF) begin
                        // overflow -> infinity
                        result <= {sign_result, 8'hFF, 23'd0};
                    end
                    else if (temp_exp[8] || temp_exp == 0) begin
                        // underflow -> zero
                        result <= {sign_result, 31'd0};
                    end
                    else begin
                        // normal case
                        result <= {sign_result, temp_exp[7:0], mantissa_result[45:23]};
                    end
                    
                    valid <= 1'b1;
                    state <= IDLE;
                end

                
                default: state <= IDLE;
            endcase
        end
    end

endmodule





module wallace_booth_multiplier_24bit(
    input wire [23:0] multiplicand,
    input wire [23:0] multiplier,
    output wire [47:0] product
);

	localparam M = 24;
	localparam NPP = 13;
	wire [337:0] pprods;
	wire [27:0] pprodsExt [0:12];
	wire [0:12] signsLow;
	wire [47:0] sum_0 [0:3];
	wire [47:0] carry_0 [0:3];
	wire [46:0] hor_cout_0 [0:3];
	wire [47:0] sum_1 [0:1];
	wire [47:0] carry_1 [0:1];
	wire [46:0] hor_cout_1 [0:1];
	wire [47:0] sum_2 [0:0];
	wire [47:0] carry_2 [0:0];
	wire [46:0] hor_cout_2 [0:0];
	pProdsGen #(
		.M(M),
		.N(M),
		.NPP(NPP)
	) pProdsGen(
		.signedFlag(1'b0),
		.multiplicand(multiplicand),
		.multiplier(multiplier),
		.pprods(pprods),
		.signsLow(signsLow)
	);
	assign pprodsExt[0] = {~pprods[337], pprods[337], pprods[337-:26]};
	genvar _gv_i_1;
	generate
		for (_gv_i_1 = 1; _gv_i_1 < NPP; _gv_i_1 = _gv_i_1 + 1) begin : pProdsLoop
			localparam i = _gv_i_1;
			assign pprodsExt[i] = {1'b1, ~pprods[((12 - i) * 26) + 25], pprods[((12 - i) * 26) + M-:25]};
		end
	endgenerate
	genvar _gv_row_0_1;
	generate
		for (_gv_row_0_1 = 0; _gv_row_0_1 < 3; _gv_row_0_1 = _gv_row_0_1 + 1) begin : row_0_for
			localparam row_0 = _gv_row_0_1;
			halfAdder ha_row0_0(
				.x(pprodsExt[row_0 * 4][0]),
				.y(signsLow[row_0 * 4]),
				.sum(sum_0[row_0][row_0 * 8]),
				.cout(carry_0[row_0][row_0 * 8])
			);
			assign sum_0[row_0][(row_0 * 8) + 1] = pprodsExt[row_0 * 4][1];
			fullAdder fa0_2(
				.x(pprodsExt[row_0 * 4][2]),
				.y(pprodsExt[(row_0 * 4) + 1][0]),
				.cin(signsLow[(row_0 * 4) + 1]),
				.sum(sum_0[row_0][(row_0 * 8) + 2]),
				.cout(carry_0[row_0][(row_0 * 8) + 2])
			);
			halfAdder ha_row0_3(
				.x(pprodsExt[row_0 * 4][3]),
				.y(pprodsExt[(row_0 * 4) + 1][1]),
				.sum(sum_0[row_0][(row_0 * 8) + 3]),
				.cout(carry_0[row_0][(row_0 * 8) + 3])
			);
			compressor_42 comp_0_4(
				.x1(pprodsExt[row_0 * 4][4]),
				.x2(pprodsExt[(row_0 * 4) + 1][2]),
				.x3(pprodsExt[(row_0 * 4) + 2][0]),
				.x4(signsLow[(row_0 * 4) + 2]),
				.cin(1'b0),
				.sum(sum_0[row_0][(row_0 * 8) + 4]),
				.carry(carry_0[row_0][(row_0 * 8) + 4]),
				.cout(hor_cout_0[row_0][(row_0 * 8) + 4])
			);
			compressor_42 comp_0_5(
				.x1(pprodsExt[row_0 * 4][5]),
				.x2(pprodsExt[(row_0 * 4) + 1][3]),
				.x3(pprodsExt[(row_0 * 4) + 2][1]),
				.x4(1'b0),
				.cin(hor_cout_0[row_0][(row_0 * 8) + 4]),
				.sum(sum_0[row_0][(row_0 * 8) + 5]),
				.carry(carry_0[row_0][(row_0 * 8) + 5]),
				.cout(hor_cout_0[row_0][(row_0 * 8) + 5])
			);
			genvar _gv_col_1;
			for (_gv_col_1 = 6; _gv_col_1 <= (27 - (row_0 * 8)); _gv_col_1 = _gv_col_1 + 1) begin : middle
				localparam col = _gv_col_1;
				compressor_42 comp_mid_col(
					.x1(pprodsExt[row_0 * 4][col]),
					.x2(pprodsExt[(row_0 * 4) + 1][col - 2]),
					.x3(pprodsExt[(row_0 * 4) + 2][col - 4]),
					.x4(pprodsExt[(row_0 * 4) + 3][col - 6]),
					.cin(hor_cout_0[row_0][((row_0 * 8) + col) - 1]),
					.sum(sum_0[row_0][(row_0 * 8) + col]),
					.carry(carry_0[row_0][(row_0 * 8) + col]),
					.cout(hor_cout_0[row_0][(row_0 * 8) + col])
				);
			end
			compressor_42 comp_0_0_M_4(
				.x1(pprodsExt[(row_0 * 4) + 1][26 - (row_0 * 8)]),
				.x2(pprodsExt[(row_0 * 4) + 2][(26 - (row_0 * 8)) - 2]),
				.x3(pprodsExt[(row_0 * 4) + 3][(26 - (row_0 * 8)) - 4]),
				.x4(pprodsExt[(row_0 * 4) + 4][(26 - (row_0 * 8)) - 6]),
				.cin(hor_cout_0[row_0][27]),
				.sum(sum_0[row_0][28]),
				.carry(carry_0[row_0][28]),
				.cout(hor_cout_0[row_0][28])
			);
			genvar _gv_j_1;
			for (_gv_j_1 = (row_0 * 4) + 2; _gv_j_1 <= 9; _gv_j_1 = _gv_j_1 + 1) begin : comp_tail_level_0_0
				localparam j = _gv_j_1;
				compressor_42 comp_0_2j(
					.x1(pprodsExt[j][25 - (row_0 * 8)]),
					.x2(pprodsExt[j + 1][(25 - (row_0 * 8)) - 2]),
					.x3(pprodsExt[j + 2][(25 - (row_0 * 8)) - 4]),
					.x4(pprodsExt[j + 3][(25 - (row_0 * 8)) - 6]),
					.cin(hor_cout_0[row_0][(29 + ((j - ((row_0 * 4) + 2)) * 2)) - 1]),
					.sum(sum_0[row_0][29 + ((j - ((row_0 * 4) + 2)) * 2)]),
					.carry(carry_0[row_0][29 + ((j - ((row_0 * 4) + 2)) * 2)]),
					.cout(hor_cout_0[row_0][29 + ((j - ((row_0 * 4) + 2)) * 2)])
				);
				compressor_42 comp_0_2j_1(
					.x1(pprodsExt[j][26 - (row_0 * 8)]),
					.x2(pprodsExt[j + 1][(26 - (row_0 * 8)) - 2]),
					.x3(pprodsExt[j + 2][(26 - (row_0 * 8)) - 4]),
					.x4(pprodsExt[j + 3][(26 - (row_0 * 8)) - 6]),
					.cin(hor_cout_0[row_0][29 + ((j - ((row_0 * 4) + 2)) * 2)]),
					.sum(sum_0[row_0][(29 + ((j - ((row_0 * 4) + 2)) * 2)) + 1]),
					.carry(carry_0[row_0][(29 + ((j - ((row_0 * 4) + 2)) * 2)) + 1]),
					.cout(hor_cout_0[row_0][(29 + ((j - ((row_0 * 4) + 2)) * 2)) + 1])
				);
			end
			compressor_42 comp_0_final_0(
				.x1(pprodsExt[10][25 - (8 * row_0)]),
				.x2(pprodsExt[11][23 - (8 * row_0)]),
				.x3(pprodsExt[12][21 - (8 * row_0)]),
				.x4(1'b0),
				.cin(hor_cout_0[row_0][44 - (8 * row_0)]),
				.sum(sum_0[row_0][45 - (8 * row_0)]),
				.carry(carry_0[row_0][45 - (8 * row_0)]),
				.cout(hor_cout_0[row_0][45 - (8 * row_0)])
			);
			compressor_42 comp_0_final_1(
				.x1(pprodsExt[10][26 - (8 * row_0)]),
				.x2(pprodsExt[11][M - (8 * row_0)]),
				.x3(pprodsExt[12][22 - (8 * row_0)]),
				.x4(1'b0),
				.cin(hor_cout_0[row_0][45 - (8 * row_0)]),
				.sum(sum_0[row_0][46 - (8 * row_0)]),
				.carry(carry_0[row_0][46 - (8 * row_0)]),
				.cout(hor_cout_0[row_0][46 - (8 * row_0)])
			);
			fullAdder fa_0_final_0(
				.x(pprodsExt[11][25 - (8 * row_0)]),
				.y(pprodsExt[12][23 - (8 * row_0)]),
				.cin(hor_cout_0[row_0][46 - (8 * row_0)]),
				.sum(sum_0[row_0][47 - (8 * row_0)]),
				.cout(carry_0[row_0][47 - (8 * row_0)])
			);
			for (_gv_j_1 = 0; _gv_j_1 < row_0; _gv_j_1 = _gv_j_1 + 3) begin : fm
				localparam j = _gv_j_1;
				halfAdder ha_0_final_0(
					.x(pprodsExt[11][26 - (8 * row_0)]),
					.y(pprodsExt[12][M - (8 * row_0)]),
					.sum(sum_0[row_0][48 - (8 * row_0)]),
					.cout(carry_0[row_0][48 - (8 * row_0)])
				);
				assign sum_0[row_0][49 - (8 * row_0)] = pprodsExt[12][17 - (8 * (row_0 - 1))];
				assign sum_0[row_0][50 - (8 * row_0)] = pprodsExt[12][18 - (8 * (row_0 - 1))];
				assign sum_0[row_0][6 + (8 * (row_0 - 1))] = signsLow[(4 * row_0) - 1];
			end
		end
	endgenerate
	assign carry_0[0][1] = 1'b0;
	assign sum_0[3][22] = signsLow[11];
	genvar _gv_j_2;
	generate
		for (_gv_j_2 = 0; _gv_j_2 < 4; _gv_j_2 = _gv_j_2 + 1) begin : level_0_endSumPassThroughs
			localparam j = _gv_j_2;
			assign sum_0[3][M + j] = pprodsExt[12][j];
		end
		for (_gv_i_1 = 0; _gv_i_1 <= 5; _gv_i_1 = _gv_i_1 + 1) begin : level_1_sumPassThrough
			localparam i = _gv_i_1;
			assign sum_1[0][i] = sum_0[0][i];
		end
		for (_gv_i_1 = 0; _gv_i_1 <= 4; _gv_i_1 = _gv_i_1 + 1) begin : level_1_carryPassThrough
			localparam i = _gv_i_1;
			assign carry_1[0][i] = carry_0[0][i];
		end
	endgenerate
	assign carry_1[0][5] = 1'b0;
	fullAdder fa_pre_0_0_6(
		.x(sum_0[0][6]),
		.y(carry_0[0][5]),
		.cin(sum_0[1][6]),
		.sum(sum_1[0][6]),
		.cout(carry_1[0][6])
	);
	halfAdder ha_pre_0_0_7(
		.x(sum_0[0][7]),
		.y(carry_0[0][6]),
		.sum(sum_1[0][7]),
		.cout(carry_1[0][7])
	);
	fullAdder fa_pre_0_0_8(
		.x(sum_0[0][8]),
		.y(carry_0[0][7]),
		.cin(sum_0[1][8]),
		.sum(sum_1[0][8]),
		.cout(carry_1[0][8])
	);
	compressor_42 ca_pre_0_9(
		.x1(sum_0[0][9]),
		.x2(carry_0[0][8]),
		.x3(sum_0[1][9]),
		.x4(carry_0[1][8]),
		.cin(1'b0),
		.sum(sum_1[0][9]),
		.carry(carry_1[0][9]),
		.cout(hor_cout_1[0][9])
	);
	compressor_42 ca_pre_0_10(
		.x1(sum_0[0][10]),
		.x2(carry_0[0][9]),
		.x3(sum_0[1][10]),
		.x4(1'b0),
		.cin(hor_cout_1[0][9]),
		.sum(sum_1[0][10]),
		.carry(carry_1[0][10]),
		.cout(hor_cout_1[0][10])
	);
	generate
		for (_gv_j_2 = 11; _gv_j_2 <= 41; _gv_j_2 = _gv_j_2 + 1) begin : comp_middle_1_0_for
			localparam j = _gv_j_2;
			compressor_42 comp_1_middle(
				.x1(sum_0[0][j]),
				.x2(carry_0[0][j - 1]),
				.x3(sum_0[1][j]),
				.x4(carry_0[1][j - 1]),
				.cin(hor_cout_1[0][j - 1]),
				.sum(sum_1[0][j]),
				.carry(carry_1[0][j]),
				.cout(hor_cout_1[0][j])
			);
		end
	endgenerate
	compressor_42 comp_1_0_middle_end_42(
		.x1(sum_0[0][42]),
		.x2(carry_0[0][41]),
		.x3(sum_0[1][42]),
		.x4(1'b0),
		.cin(hor_cout_1[0][41]),
		.sum(sum_1[0][42]),
		.carry(carry_1[0][42]),
		.cout(hor_cout_1[0][42])
	);
	fullAdder fa_1_0_middle_end_43(
		.x(sum_0[0][43]),
		.y(carry_0[0][42]),
		.cin(hor_cout_1[0][42]),
		.sum(sum_1[0][43]),
		.cout(carry_1[0][43])
	);
	generate
		for (_gv_j_2 = 44; _gv_j_2 <= 47; _gv_j_2 = _gv_j_2 + 1) begin : level_1_44_47
			localparam j = _gv_j_2;
			halfAdder ha_pre_0(
				.x(sum_0[0][j]),
				.y(carry_0[0][j - 1]),
				.sum(sum_1[0][j]),
				.cout(carry_1[0][j])
			);
		end
	endgenerate
	halfAdder ha_pre_0_1(
		.x(sum_0[2][17]),
		.y(carry_0[2][16]),
		.sum(sum_1[1][17]),
		.cout(carry_1[1][17])
	);
	generate
		for (_gv_j_2 = 19; _gv_j_2 <= 21; _gv_j_2 = _gv_j_2 + 1) begin : level_1_19_21
			localparam j = _gv_j_2;
			halfAdder ha_pre_0(
				.x(sum_0[2][j]),
				.y(carry_0[2][j - 1]),
				.sum(sum_1[1][j]),
				.cout(carry_1[1][j])
			);
		end
	endgenerate
	assign sum_1[1][14] = sum_0[2][14];
	assign sum_1[1][16] = sum_0[2][16];
	assign sum_1[1][18] = sum_0[2][18];
	fullAdder fa_pre_0_22(
		.x(sum_0[2][22]),
		.y(carry_0[2][21]),
		.cin(sum_0[3][22]),
		.sum(sum_1[1][22]),
		.cout(carry_1[1][22])
	);
	halfAdder ha_pre_0_23(
		.x(sum_0[2][23]),
		.y(carry_0[2][22]),
		.sum(sum_1[1][23]),
		.cout(carry_1[1][23])
	);
	generate
		for (_gv_j_2 = 24; _gv_j_2 <= 27; _gv_j_2 = _gv_j_2 + 1) begin : level_1_24_27
			localparam j = _gv_j_2;
			fullAdder fa_middle_0_1(
				.x(sum_0[2][j]),
				.y(carry_0[2][j - 1]),
				.cin(sum_0[3][j]),
				.sum(sum_1[1][j]),
				.cout(carry_1[1][j])
			);
		end
	endgenerate
	assign sum_1[1][34] = sum_0[2][34];
	generate
		for (_gv_j_2 = 28; _gv_j_2 <= 33; _gv_j_2 = _gv_j_2 + 1) begin : level_1_28_33
			localparam j = _gv_j_2;
			halfAdder ha_tail_0_1(
				.x(sum_0[2][j]),
				.y(carry_0[2][j - 1]),
				.sum(sum_1[1][j]),
				.cout(carry_1[1][j])
			);
		end
		for (_gv_i_1 = 0; _gv_i_1 <= 13; _gv_i_1 = _gv_i_1 + 1) begin : level_2_sumPassThrough
			localparam i = _gv_i_1;
			assign sum_2[0][i] = sum_1[0][i];
		end
		for (_gv_i_1 = 0; _gv_i_1 <= 12; _gv_i_1 = _gv_i_1 + 1) begin : level_2_carryPassThrough
			localparam i = _gv_i_1;
			assign carry_2[0][i] = carry_1[0][i];
		end
	endgenerate
	assign carry_2[0][13] = 1'b0;
	fullAdder fa_2_pre_14(
		.x(sum_1[0][14]),
		.y(carry_1[0][13]),
		.cin(sum_1[1][14]),
		.sum(sum_2[0][14]),
		.cout(carry_2[0][14])
	);
	halfAdder ha_2_pre_15(
		.x(sum_1[0][15]),
		.y(carry_1[0][14]),
		.sum(sum_2[0][15]),
		.cout(carry_2[0][15])
	);
	fullAdder fa_2_pre_16(
		.x(sum_1[0][16]),
		.y(carry_1[0][15]),
		.cin(sum_1[1][16]),
		.sum(sum_2[0][16]),
		.cout(carry_2[0][16])
	);
	fullAdder fa_2_pre_17(
		.x(sum_1[0][17]),
		.y(carry_1[0][16]),
		.cin(sum_1[1][17]),
		.sum(sum_2[0][17]),
		.cout(carry_2[0][17])
	);
	compressor_42 comp_2_pre_18(
		.x1(sum_1[0][18]),
		.x2(carry_1[0][17]),
		.x3(sum_1[1][18]),
		.x4(carry_1[1][17]),
		.cin(1'b0),
		.sum(sum_2[0][18]),
		.carry(carry_2[0][18]),
		.cout(hor_cout_2[0][18])
	);
	compressor_42 comp_2_pre_19(
		.x1(sum_1[0][19]),
		.x2(carry_1[0][18]),
		.x3(sum_1[1][19]),
		.x4(1'b0),
		.cin(hor_cout_2[0][18]),
		.sum(sum_2[0][19]),
		.carry(carry_2[0][19]),
		.cout(hor_cout_2[0][19])
	);
	generate
		for (_gv_i_1 = 20; _gv_i_1 <= 34; _gv_i_1 = _gv_i_1 + 1) begin : comp_2_20_34
			localparam i = _gv_i_1;
			compressor_42 comp_2(
				.x1(sum_1[0][i]),
				.x2(carry_1[0][i - 1]),
				.x3(sum_1[1][i]),
				.x4(carry_1[1][i - 1]),
				.cin(hor_cout_2[0][i - 1]),
				.sum(sum_2[0][i]),
				.carry(carry_2[0][i]),
				.cout(hor_cout_2[0][i])
			);
		end
	endgenerate
	fullAdder fa_2_pre_35(
		.x(sum_1[0][35]),
		.y(carry_1[0][34]),
		.cin(hor_cout_2[0][34]),
		.sum(sum_2[0][35]),
		.cout(carry_2[0][35])
	);
	generate
		for (_gv_i_1 = 36; _gv_i_1 <= 47; _gv_i_1 = _gv_i_1 + 1) begin : level_2_36_47
			localparam i = _gv_i_1;
			halfAdder ha_2_pre_51(
				.x(sum_1[0][i]),
				.y(carry_1[0][i - 1]),
				.sum(sum_2[0][i]),
				.cout(carry_2[0][i])
			);
		end
	endgenerate
	claAddSub48 finalCLAadder48(
		.sub(1'b0),
		.cin(1'b0),
		.x({sum_2[0][47:0]}),
		.y({carry_2[0][46:0], 1'b0}),
		.out(product[47:0]),
		.cout(),
		.v(),
		.g(),
		.p()
	);
endmodule



module halfAdder (
	x,
	y,
	sum,
	cout
);
	input wire x;
	input wire y;
	output wire sum;
	output wire cout;
	assign sum = x ^ y;
	assign cout = x & y;
endmodule


module fullAdder (
	x,
	y,
	cin,
	sum,
	cout
);
	input wire x;
	input wire y;
	input wire cin;
	output wire sum;
	output wire cout;
	assign sum = (x ^ y) ^ cin;
	assign cout = ((x & y) | (x & cin)) | (y & cin);
endmodule


module compressor_42 (
	x1,
	x2,
	x3,
	x4,
	cin,
	sum,
	carry,
	cout
);
	input wire x1;
	input wire x2;
	input wire x3;
	input wire x4;
	input wire cin;
	output wire sum;
	output wire carry;
	output wire cout;
	wire xor12;
	wire xor34;
	wire xor1234;
	assign xor12 = x1 ^ x2;
	assign xor34 = x3 ^ x4;
	assign xor1234 = xor12 ^ xor34;
	assign cout = (xor12 ? x3 : x1);
	assign carry = (xor1234 ? cin : x4);
	assign sum = xor1234 ^ cin;
endmodule



module claAddSub48 (
	sub,
	cin,
	x,
	y,
	out,
	cout,
	v,
	g,
	p
);
	parameter M = 48;
	input wire sub;
	input wire cin;
	input wire [M - 1:0] x;
	input wire [M - 1:0] y;
	output wire [M - 1:0] out;
	output wire cout;
	output wire v;
	output wire g;
	output wire p;
	wire [1:0] ci;
	wire [1:0] gi;
	wire [1:0] pi;
	wire [1:0] vi;
	wire [M - 1:0] yn;
	wire icout;
	assign ci[0] = sub | cin;
	assign yn = y ^ {M {sub}};
	localparam M2 = M / 2;
	genvar _gv_i_1;
	generate
		for (_gv_i_1 = 0; _gv_i_1 <= 1; _gv_i_1 = _gv_i_1 + 1) begin : cla24Adders
			localparam i = _gv_i_1;
			claAddSub24 a24(
				.sub(1'b0),
				.cin(ci[i]),
				.x(x[((M2 * i) + M2) - 1:M2 * i]),
				.y(yn[((M2 * i) + M2) - 1:M2 * i]),
				.out(out[((M2 * i) + M2) - 1:M2 * i]),
				.cout(),
				.v(vi[i]),
				.g(gi[i]),
				.p(pi[i])
			);
		end
	endgenerate
	claLogic2 cla(
		.cin(ci[0]),
		.gi(gi),
		.pi(pi),
		.c1(ci[1]),
		.g(g),
		.p(p),
		.cout(icout)
	);
	assign cout = icout ^ sub;
	assign v = vi[1];
endmodule


module claAddSub24 (
	sub,
	cin,
	x,
	y,
	out,
	cout,
	v,
	g,
	p
);
	parameter M = 24;
	input wire sub;
	input wire cin;
	input wire [M - 1:0] x;
	input wire [M - 1:0] y;
	output wire [M - 1:0] out;
	output wire cout;
	output wire v;
	output wire g;
	output wire p;
	wire [1:0] ci;
	wire [1:0] gi;
	wire [1:0] pi;
	wire [M - 1:0] yn;
	wire icout;
	assign ci[0] = sub | cin;
	assign yn = y ^ {M {sub}};
	localparam M1 = 16;
	genvar _gv_i_1;
	generate
		for (_gv_i_1 = 0; _gv_i_1 <= 0; _gv_i_1 = _gv_i_1 + 1) begin : claFor
			localparam i = _gv_i_1;
			claAddSubGen #(.M(16)) aM1(
				.sub(1'b0),
				.cin(ci[i]),
				.x(x[((M1 * i) + M1) - 1:M1 * i]),
				.y(yn[((M1 * i) + M1) - 1:M1 * i]),
				.out(out[((M1 * i) + M1) - 1:M1 * i]),
				.cout(),
				.v(),
				.g(gi[i]),
				.p(pi[i])
			);
		end
	endgenerate
	claAddSubGen #(.M(8)) a8(
		.sub(1'b0),
		.cin(ci[1]),
		.x(x[23:16]),
		.y(yn[23:16]),
		.out(out[23:16]),
		.cout(),
		.v(v),
		.g(gi[1]),
		.p(pi[1])
	);
	claLogic2 cla(
		.cin(ci[0]),
		.gi(gi),
		.pi(pi),
		.c1(ci[1]),
		.g(g),
		.p(p),
		.cout(icout)
	);
	assign cout = icout ^ sub;
endmodule

module claAddSubGen (
	sub,
	cin,
	x,
	y,
	out,
	cout,
	v,
	g,
	p
);
	parameter M = 0;
	input wire sub;
	input wire cin;
	input wire [M - 1:0] x;
	input wire [M - 1:0] y;
	output wire [M - 1:0] out;
	output wire cout;
	output wire v;
	output wire g;
	output wire p;
	wire [1:0] ci;
	wire [1:0] gi;
	wire [1:0] pi;
	wire [1:0] vi;
	wire [M - 1:0] yn;
	wire icout;
	assign ci[0] = sub ^ cin;
	assign yn = y ^ {M {sub}};
	localparam M2 = M / 2;
	genvar _gv_i_1;
	generate
		for (_gv_i_1 = 0; _gv_i_1 <= 1; _gv_i_1 = _gv_i_1 + 1) begin : claFor
			localparam i = _gv_i_1;
			if (M <= 8) begin : M_lte_8
				claAddSub4 a4(
					.sub(1'b0),
					.cin(ci[i]),
					.x(x[((M2 * i) + M2) - 1:M2 * i]),
					.y(yn[((M2 * i) + M2) - 1:M2 * i]),
					.out(out[((M2 * i) + M2) - 1:M2 * i]),
					.cout(),
					.v(vi[i]),
					.g(gi[i]),
					.p(pi[i])
				);
			end
			else begin : claAdders
				claAddSubGen #(.M(M2)) aM(
					.sub(1'b0),
					.cin(ci[i]),
					.x(x[((M2 * i) + M2) - 1:M2 * i]),
					.y(yn[((M2 * i) + M2) - 1:M2 * i]),
					.out(out[((M2 * i) + M2) - 1:M2 * i]),
					.cout(),
					.v(vi[i]),
					.g(gi[i]),
					.p(pi[i])
				);
			end
		end
	endgenerate
	claLogic2 cla(
		.cin(ci[0]),
		.gi(gi),
		.pi(pi),
		.c1(ci[1]),
		.g(g),
		.p(p),
		.cout(icout)
	);
	assign cout = icout ^ sub;
	assign v = vi[1];
endmodule

module fullAdderPG (
	cin,
	x,
	y,
	sum,
	g,
	p
);
	input wire cin;
	input wire x;
	input wire y;
	output wire sum;
	output wire g;
	output wire p;
	assign p = x ^ y;
	assign g = x & y;
	assign sum = p ^ cin;
endmodule
module claAddSub4 (
	sub,
	cin,
	x,
	y,
	out,
	cout,
	g,
	p,
	v
);
	input wire sub;
	input wire cin;
	input wire [3:0] x;
	input wire [3:0] y;
	output wire [3:0] out;
	output wire cout;
	output wire g;
	output wire p;
	output wire v;
	wire [3:0] gi;
	wire [3:0] pi;
	wire [3:0] ci;
	wire [3:0] yn;
	assign ci[0] = sub | cin;
	assign yn = y ^ {4 {sub}};
	genvar _gv_i_1;
	generate
		for (_gv_i_1 = 0; _gv_i_1 <= 3; _gv_i_1 = _gv_i_1 + 1) begin : fullAdderGen
			localparam i = _gv_i_1;
			fullAdderPG fa_i(
				.x(x[i]),
				.y(yn[i]),
				.cin(ci[i]),
				.sum(out[i]),
				.g(gi[i]),
				.p(pi[i])
			);
		end
	endgenerate
	claLogic4 cla4(
		.cin(ci[0]),
		.pi(pi),
		.gi(gi),
		.ci(ci[3:1]),
		.g(g),
		.p(p),
		.cout(cout)
	);
	assign v = cout ^ ci[3];
endmodule

module claLogic4 (
	cin,
	gi,
	pi,
	ci,
	g,
	p,
	cout
);
	input wire cin;
	input wire [3:0] gi;
	input wire [3:0] pi;
	output wire [3:1] ci;
	output wire g;
	output wire p;
	output wire cout;
	assign ci[1] = (cin & pi[0]) | gi[0];
	assign ci[2] = (((cin & pi[0]) & pi[1]) | (gi[0] & pi[1])) | gi[1];
	assign ci[3] = (((((cin & pi[0]) & pi[1]) & pi[2]) | ((gi[0] & pi[1]) & pi[2])) | (gi[1] & pi[2])) | gi[2];
	assign p = ((pi[0] & pi[1]) & pi[2]) & pi[3];
	assign g = (((((gi[0] & pi[1]) & pi[2]) & pi[3]) | ((gi[1] & pi[2]) & pi[3])) | (gi[2] & pi[3])) | gi[3];
	assign cout = (cin & p) | g;
endmodule


module pProdsGen (
	signedFlag,
	multiplicand,
	multiplier,
	pprods,
	signsLow
);
	parameter M = 16;
	parameter N = 16;
	parameter NPP = (N / 2) + 1;
	input wire signedFlag;
	input wire [M - 1:0] multiplicand;
	input wire [N - 1:0] multiplier;
	output wire [((M + 1) >= 0 ? (NPP * (M + 2)) - 1 : (NPP * (1 - (M + 1))) + (M + 0)):((M + 1) >= 0 ? 0 : M + 1)] pprods;
	output wire [0:NPP - 1] signsLow;
	localparam msbZeroPadding = 2 - (N % 2);
	wire [N + msbZeroPadding:0] paddedMultiplier;
	assign paddedMultiplier = {{msbZeroPadding {multiplier[N - 1] && ((N % 2) == 1)}}, multiplier, 1'b0};
	genvar _gv_i_1;
	generate
		for (_gv_i_1 = 0; _gv_i_1 < NPP; _gv_i_1 = _gv_i_1 + 1) begin : pps
			localparam i = _gv_i_1;
			wire zero;
			wire neg;
			wire two;
			boothRecoder3 br(
				paddedMultiplier[2 * (i + 1):2 * i],
				zero,
				neg,
				two
			);
			pProd #(
				.INPUT_SIZE(M),
				.OUTPUT_SIZE(M + 2)
			) pp_i(
				.signedFlag(signedFlag),
				.in(multiplicand),
				.out(pprods[((M + 1) >= 0 ? 0 : M + 1) + (((NPP - 1) - i) * ((M + 1) >= 0 ? M + 2 : 1 - (M + 1)))+:((M + 1) >= 0 ? M + 2 : 1 - (M + 1))]),
				.signLow(signsLow[i]),
				.zero(zero | (((i == (NPP - 1)) & signedFlag) & ((N % 2) == 0))),
				.neg(neg),
				.two(two)
			);
		end
	endgenerate
endmodule


module claLogic2 (
	cin,
	gi,
	pi,
	c1,
	g,
	p,
	cout
);
	input wire cin;
	input wire [1:0] gi;
	input wire [1:0] pi;
	output wire c1;
	output wire g;
	output wire p;
	output wire cout;
	assign c1 = (cin & pi[0]) | gi[0];
	assign p = pi[0] & pi[1];
	assign g = (gi[0] & pi[1]) | gi[1];
	assign cout = (cin & p) | g;
endmodule


module boothRecoder3 (
	in,
	zero,
	neg,
	two
);
	reg _sv2v_0;
	input wire [2:0] in;
	output reg zero;
	output reg neg;
	output reg two;
	always @(*) begin
		if (_sv2v_0)
			;
		case (in)
			3'b000: begin
				zero = 1;
				neg = 0;
				two = 0;
			end
			3'b001: begin
				zero = 0;
				neg = 0;
				two = 0;
			end
			3'b010: begin
				zero = 0;
				neg = 0;
				two = 0;
			end
			3'b011: begin
				zero = 0;
				neg = 0;
				two = 1;
			end
			3'b100: begin
				zero = 0;
				neg = 1;
				two = 1;
			end
			3'b101: begin
				zero = 0;
				neg = 1;
				two = 0;
			end
			3'b110: begin
				zero = 0;
				neg = 1;
				two = 0;
			end
			3'b111: begin
				zero = 1;
				neg = 1;
				two = 0;
			end
		endcase
	end
	initial _sv2v_0 = 0;
endmodule


module pProd (
	signedFlag,
	in,
	out,
	signLow,
	zero,
	neg,
	two
);
	reg _sv2v_0;
	parameter INPUT_SIZE = 16;
	parameter OUTPUT_SIZE = INPUT_SIZE + 2;
	input wire signedFlag;
	input wire [INPUT_SIZE - 1:0] in;
	output reg [OUTPUT_SIZE - 1:0] out;
	output reg signLow;
	input wire zero;
	input wire neg;
	input wire two;
	reg [OUTPUT_SIZE - 1:0] res;
	always @(*) begin
		if (_sv2v_0)
			;
		if (zero == 1) begin
			out = {OUTPUT_SIZE {1'b0}};
			res = {OUTPUT_SIZE {1'b0}};
			signLow = 1'b0;
		end
		else begin
			if (two == 1)
				res = {{(OUTPUT_SIZE - INPUT_SIZE) - 1 {signedFlag & in[INPUT_SIZE - 1]}}, in[INPUT_SIZE - 1:0], 1'b0};
			else
				res = {{OUTPUT_SIZE - INPUT_SIZE {signedFlag & in[INPUT_SIZE - 1]}}, in};
			if (neg == 1)
				res[OUTPUT_SIZE - 1:0] = ~res[OUTPUT_SIZE - 1:0];
			else
				res[OUTPUT_SIZE - 1:0] = res[OUTPUT_SIZE - 1:0];
			out[OUTPUT_SIZE - 2:0] = res[OUTPUT_SIZE - 2:0];
			if (signedFlag == 1)
				out[OUTPUT_SIZE - 1] = neg != in[INPUT_SIZE - 1];
			else
				out[OUTPUT_SIZE - 1] = res[OUTPUT_SIZE - 1];
			signLow = neg;
		end
	end
	initial _sv2v_0 = 0;
endmodule


