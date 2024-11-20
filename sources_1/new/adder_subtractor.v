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

    // Step 5: Normalize result
    reg [7:0] result_exp;
    reg [23:0] result_mantissa;
    always @(*) begin
        if (mantissa_result[24]) begin
            // Normalization shift if there's a carry out
            result_mantissa = mantissa_result[24:1]; // Shift right by 1
            result_exp = aligned_exp + 1;
        end else begin
            result_mantissa = mantissa_result[23:0];
            result_exp = aligned_exp;
            // Normalize mantissa by left-shifting until MSB is 1
            while (result_mantissa[23] == 0 && result_exp > 0) begin
                result_mantissa = result_mantissa << 1;
                result_exp = result_exp - 1;
            end
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