module FP32_CLA_Adder(
    input [31:0] a,          // First 32-bit floating-point input
    input [31:0] b,          // Second 32-bit floating-point input
    output [31:0] result     // Resulting 32-bit floating-point output
);
    // Step 1: Extract fields
    wire sign_a = a[31];
    wire sign_b = b[31];
    wire [7:0] exp_a = a[30:23];
    wire [7:0] exp_b = b[30:23];
    
    wire [23:0] mantissa_a = (exp_a == 8'b0) ? {1'b0, a[22:0]} : {1'b1, a[22:0]};
    wire [23:0] mantissa_b = (exp_b == 8'b0) ? {1'b0, b[22:0]} : {1'b1, b[22:0]};

//    wire [23:0] mantissa_a = {1'b1, a[22:0]}; // Implicit 1 for normalized mantissa
//    wire [23:0] mantissa_b = {1'b1, b[22:0]}; // Implicit 1 for normalized mantissa

    // Step 2: Exponent difference
    wire [7:0] exp_diff = (exp_a > exp_b) ? (exp_a - exp_b) : (exp_b - exp_a);

    // Step 3: Align mantissas
    wire [23:0] mantissa_a_shifted = (exp_a >= exp_b) ? mantissa_a : (mantissa_a >> exp_diff);
    wire [23:0] mantissa_b_shifted = (exp_b >= exp_a) ? mantissa_b : (mantissa_b >> exp_diff);
    wire [7:0] aligned_exp = (exp_a >= exp_b) ? exp_a : exp_b;

    // Step 4: Perform mantissa addition/subtraction
    reg [24:0] mantissa_result; // One extra bit for possible carry
    reg result_sign;
    
    
    always @(*) begin
        if (sign_a == sign_b) begin
            // Same signs: add mantissas
            mantissa_result = {1'b0, mantissa_a_shifted} + {1'b0, mantissa_b_shifted};
            result_sign = sign_a;
        end else begin
            // Different signs: subtract smaller magnitude from larger
            if (mantissa_a_shifted >= mantissa_b_shifted) begin
                mantissa_result = {1'b0, mantissa_a_shifted} - {1'b0, mantissa_b_shifted};
                result_sign = sign_a;
            end else begin
                mantissa_result = {1'b0, mantissa_b_shifted} - {1'b0, mantissa_a_shifted};
                result_sign = sign_b;
            end
        end
    end

      // Step 5: Normalize result using Leading Zero Counter
    reg [7:0] result_exp;
    reg [23:0] result_mantissa;
    reg [4:0] leading_zeros; // 5 bits to count up to 24

    always @(*) begin
        if (mantissa_result[24]) begin
            // Normalization shift if there's a carry out
            result_mantissa = mantissa_result[24:1]; // Shift right by 1
            result_exp = aligned_exp + 1;
        end else begin
            // Use Leading Zero Counter
            if (mantissa_result[23]) leading_zeros = 0;
            else if (mantissa_result[22]) leading_zeros = 1;
            else if (mantissa_result[21]) leading_zeros = 2;
            else if (mantissa_result[20]) leading_zeros = 3;
            else if (mantissa_result[19]) leading_zeros = 4;
            else if (mantissa_result[18]) leading_zeros = 5;
            else if (mantissa_result[17]) leading_zeros = 6;
            else if (mantissa_result[16]) leading_zeros = 7;
            else if (mantissa_result[15]) leading_zeros = 8;
            else if (mantissa_result[14]) leading_zeros = 9;
            else if (mantissa_result[13]) leading_zeros = 10;
            else if (mantissa_result[12]) leading_zeros = 11;
            else if (mantissa_result[11]) leading_zeros = 12;
            else if (mantissa_result[10]) leading_zeros = 13;
            else if (mantissa_result[9]) leading_zeros = 14;
            else if (mantissa_result[8]) leading_zeros = 15;
            else if (mantissa_result[7]) leading_zeros = 16;
            else if (mantissa_result[6]) leading_zeros = 17;
            else if (mantissa_result[5]) leading_zeros = 18;
            else if (mantissa_result[4]) leading_zeros = 19;
            else if (mantissa_result[3]) leading_zeros = 20;
            else if (mantissa_result[2]) leading_zeros = 21;
            else if (mantissa_result[1]) leading_zeros = 22;
            else if (mantissa_result[0]) leading_zeros = 23;
            else leading_zeros = 24; // All zeros

            result_mantissa = mantissa_result[23:0] << leading_zeros;
            if (aligned_exp > leading_zeros)
                result_exp = aligned_exp - leading_zeros;
            else
                result_exp = 0; // Underflow to zero or denormalized number
        end
    end
    // Step 6: Assemble the final result
    assign result = {result_sign, result_exp, result_mantissa[22:0]};
endmodule


// 32-bit Floating-Point Subtractor Module
module FP32_CLA_Subtractor(
    input [31:0] a,          // Minuend (First operand)
    input [31:0] b,          // Subtrahend (Second operand)
    output [31:0] result     // Resulting 32-bit floating-point output
);
    // Negate the subtrahend by flipping its sign bit
    wire [31:0] b_negated;
    assign b_negated = {~b[31], b[30:0]};

    // Use the FP32_CLA_Adder module to compute a + (-b)
    FP32_CLA_Adder adder_inst (
        .a(a),
        .b(b_negated),
        .result(result)
    );
endmodule