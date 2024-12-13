module FP32_CLA_Adder(
    input [31:0] a,          // First 32-bit floating-point input
    input [31:0] b,          // Second 32-bit floating-point input
    output [31:0] result     // Resulting 32-bit floating-point output
);
    // Step 1: Extract fields from the 32-bit IEEE 754 floating-point format
    // The format is: [Sign(1 bit) | Exponent(8 bits) | Mantissa(23 bits)]
    wire sign_a = a[31];             // Sign bit of 'a'
    wire sign_b = b[31];             // Sign bit of 'b'
    wire [7:0] exp_a = a[30:23];     // Exponent field of 'a'
    wire [7:0] exp_b = b[30:23];     // Exponent field of 'b'
    
    // Extract the mantissa (also known as fraction) and add the implicit leading 1 if normalized
    // If exponent is zero, it indicates either zero or a denormalized number, so no implicit '1'.
    wire [23:0] mantissa_a = (exp_a == 8'b0) ? {1'b0, a[22:0]} : {1'b1, a[22:0]};
    wire [23:0] mantissa_b = (exp_b == 8'b0) ? {1'b0, b[22:0]} : {1'b1, b[22:0]};

    // Step 2: Compute the exponent difference
    // This will help in aligning the smaller mantissa before addition/subtraction
    wire [7:0] exp_diff = (exp_a > exp_b) ? (exp_a - exp_b) : (exp_b - exp_a);

    // Step 3: Align mantissas by shifting the smaller one
    // The mantissa corresponding to the smaller exponent is right-shifted to align both mantissas.
    wire [23:0] mantissa_a_shifted = (exp_a >= exp_b) ? mantissa_a : (mantissa_a >> exp_diff);
    wire [23:0] mantissa_b_shifted = (exp_b >= exp_a) ? mantissa_b : (mantissa_b >> exp_diff);

    // The aligned exponent is the larger of the two exponents
    wire [7:0] aligned_exp = (exp_a >= exp_b) ? exp_a : exp_b;

    // Step 4: Perform mantissa addition or subtraction
    // If the signs are the same, we add the mantissas.
    // If different, we subtract the smaller mantissa from the larger one.
    reg [24:0] mantissa_result; // Extra bit for carry out during addition
    reg result_sign;            // The resulting sign bit

    always @(*) begin
        if (sign_a == sign_b) begin
            // Same sign: simply add the mantissas
            mantissa_result = {1'b0, mantissa_a_shifted} + {1'b0, mantissa_b_shifted};
            result_sign = sign_a; // Result sign is the same as both inputs
        end else begin
            // Different signs: effectively perform subtraction
            // The sign of the result is the sign of the larger magnitude operand
            if (mantissa_a_shifted >= mantissa_b_shifted) begin
                mantissa_result = {1'b0, mantissa_a_shifted} - {1'b0, mantissa_b_shifted};
                result_sign = sign_a;
            end else begin
                mantissa_result = {1'b0, mantissa_b_shifted} - {1'b0, mantissa_a_shifted};
                result_sign = sign_b;
            end
        end
    end

    // Step 5: Normalize the result
    // After addition/subtraction, we may need to shift the mantissa to restore normalized form.
    // Normalization ensures the leading bit of the mantissa is '1' for normalized numbers
    // unless the result is zero or denormalized.
    reg [7:0] result_exp;       // Final exponent after normalization
    reg [23:0] result_mantissa; // Final mantissa after normalization
    reg [4:0] leading_zeros;    // Count leading zeros to normalize the mantissa

    always @(*) begin
        if (mantissa_result[24]) begin
            // If there is an overflow in the mantissa (e.g., carry out),
            // shift right by one and increase exponent by one.
            result_mantissa = mantissa_result[24:1]; 
            result_exp = aligned_exp + 1;
        end else begin
            // If no overflow, count leading zeros to shift the mantissa left if needed.
            // This series of if-else statements finds the position of the first '1'.
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
            else leading_zeros = 24; // The mantissa is all zeros

            // Shift the mantissa left to normalize it
            result_mantissa = mantissa_result[23:0] << leading_zeros;
            // Adjust the exponent based on how many bits we shifted
            if (aligned_exp > leading_zeros)
                result_exp = aligned_exp - leading_zeros;
            else
                // If we cannot reduce exponent further, we end up with a denormalized number or zero.
                result_exp = 0;
        end
    end

    // Step 6: Assemble the final 32-bit floating-point number
    // Format again: [Sign(1) | Exponent(8) | Mantissa(23)]
    assign result = {result_sign, result_exp, result_mantissa[22:0]};

endmodule


// 32-bit Floating-Point Subtractor Module
module FP32_CLA_Subtractor(
    input [31:0] a,          // Minuend (First operand)
    input [31:0] b,          // Subtrahend (Second operand)
    output [31:0] result     // 32-bit floating-point subtraction result
);
    // To subtract b from a (a - b), we can add a and (-b).
    // Negate b by flipping its sign bit.
    wire [31:0] b_negated;
    assign b_negated = {~b[31], b[30:0]};

    // Reuse the FP32_CLA_Adder to perform a + (-b)
    FP32_CLA_Adder adder_inst (
        .a(a),
        .b(b_negated),
        .result(result)
    );
endmodule
