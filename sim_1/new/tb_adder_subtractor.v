`timescale 1ns / 1ps

module tb_FP32_CLA_Adder;
    // Inputs
    reg [31:0] a;
    reg [31:0] b;

    // Expected output
    reg [31:0] expected_result;

    // Outputs
    wire [31:0] result;

    // Instantiate the Unit Under Test (UUT)
    FP32_CLA_Adder uut (
        .a(a),
        .b(b),
        .result(result)
    );

    // Task to check the result
    task check_result;
        input [31:0] expected;
        begin
            if (result === expected) begin
                $display("PASS: a = %e, b = %e, result = %e", a, b, result);
            end else begin
                $display("FAIL: a = %e, b = %e, result = %e, expected = %e", a, b, result, expected);
            end
        end
    endtask

    initial begin
        // Test 1: 1.5 + 2.5 = 4.0 (Expected result = 0x40800000)
        a = 32'h3FC00000; // 1.5 in IEEE 754
        b = 32'h40200000; // 2.5 in IEEE 754
        expected_result = 32'h40800000; // 4.0 in IEEE 754
        #10;
        check_result(expected_result);

        // Test 2: -3.25 + 1.75 = -1.5 (Expected result = 0xBF800000)
        a = 32'b11000000010100000000000000000000 ; // -3.25 in IEEE 754
        b = 32'b00111111111000000000000000000000; // 1.75 in IEEE 754
        expected_result = 32'b10111111110000000000000000000000; // -1.5 in IEEE 754
        #10;
        check_result(expected_result);

        // Test 3: 1.0 + 1.0 = 2.0 (Expected result = 0x40000000)
        a = 32'h3F800000; // 1.0 in IEEE 754
        b = 32'h3F800000; // 1.0 in IEEE 754
        expected_result = 32'b01000000000000000000000000000000; // 2.0 in IEEE 754
        #10;
        check_result(expected_result);

        // Test 4: -1.0 + 1.0 = 0.0 (Expected result = 0x00000000)
        a = 32'b10111111100000000000000000000000; // -1.0 in IEEE 754
        b = 32'b00111111100000000000000000000000; // 1.0 in IEEE 754
        expected_result = 32'b10000000000000000000000000000000; // 0.0 in IEEE 754
        #10;
        check_result(expected_result);

        // Test 5: Large numbers 1.0e10 + 1.0e10 = 2.0e10 (Expected result = ~0x4E947AE1)
        a = 32'b01010000000101010000001011111001; // 1.0e10 in IEEE 754
        b = 32'b01010000000101010000001011111001; // 1.0e10 in IEEE 754
        expected_result = 32'b01010000100101010000001011111001; // Expected result (rounded approximation)
        #10;
        check_result(expected_result);

        // Test 6: Small numbers 1.0e-10 + 1.0e-10 = 2.0e-10 (Expected result ~ 0x2E927C20)
        a = 32'b00101110110110111110011011111111; // 1.0e-10 in IEEE 754
        b = 32'b00101110110110111110011011111111; // 1.0e-10 in IEEE 754
        expected_result = 32'b00101111010110111110011011111111; // Expected result (rounded approximation)
        #10;
        check_result(expected_result);

        // Finish simulation
        $finish;
    end

endmodule


`timescale 1ns / 1ps

module FP32_CLA_Subtractor_tb;
    reg [31:0] a;
    reg [31:0] b;
    wire [31:0] result;

    // Instantiate the subtractor module
    FP32_CLA_Subtractor subtractor_inst (
        .a(a),
        .b(b),
        .result(result)
    );

    // Function to convert IEEE 754 floating-point to real number for display
    function real fp_to_real;
        input [31:0] fp;
        reg [63:0] temp;
        begin
            temp = {32'b0, fp};
            fp_to_real = $bitstoreal(temp);
        end
    endfunction

    initial begin
        // Display header
        $display("---------------------------------------------------------");
        $display(" Floating-Point Subtractor Testbench");
        $display("---------------------------------------------------------");
        $display("Test |       a        |       b        |    a - b    ");
        $display("---------------------------------------------------------");

        // Test 1: Subtract 1.5 - 2.75
        a = 32'h3FC00000; // 1.5 in IEEE 754
        b = 32'h40300000; // 2.75 in IEEE 754
        #10;
        $display(" 1   | %h | %h | %h", a, b, result);

        // Test 2: Subtract -3.0 - 1.25
        a = 32'hC0400000; // -3.0 in IEEE 754
        b = 32'h3FA00000; // 1.25 in IEEE 754
        #10;
        $display(" 2   | %h | %h | %h", a, b, result);

        // Test 3: Subtract 5.5 - (-2.5)
        a = 32'h40B00000; // 5.5 in IEEE 754
        b = 32'hC0200000; // -2.5 in IEEE 754
        #10;
        $display(" 3   | %h | %h | %h", a, b, result);

        // Test 4: Subtract -1.0 - (-1.0)
        a = 32'hBF800000; // -1.0 in IEEE 754
        b = 32'hBF800000; // -1.0 in IEEE 754
        #10;
        $display(" 4   | %h | %h | %h", a, b, result);

        // Test 5: Subtract 0 - 0
        a = 32'h00000000; // 0.0 in IEEE 754
        b = 32'h00000000; // 0.0 in IEEE 754
        #10;
        $display(" 5   | %h | %h | %h", a, b, result);

        // Test 6: Subtract Max Positive - Max Positive
        a = 32'h7F7FFFFF; // Max Normalized Positive Number
        b = 32'h7F7FFFFF; // Max Normalized Positive Number
        #10;
        $display(" 6   | %h | %h | %h", a, b, result);

        // Test 7: Subtract Min Positive - Min Positive
        a = 32'h00800000; // Smallest Normalized Positive Number
        b = 32'h00800000; // Smallest Normalized Positive Number
        #10;
        $display(" 7   | %h | %h | %h", a, b, result);

        // Test 8: Subtract Positive Infinity - Negative Infinity
        a = 32'h7F800000; // Positive Infinity
        b = 32'hFF800000; // Negative Infinity
        #10;
        $display(" 8   | %h | %h | %h", a, b, result);

        // Test 9: Subtract NaN - Any Number
        a = 32'h7FC00000; // NaN
        b = 32'h3F800000; // 1.0 in IEEE 754
        #10;
        $display(" 9   | %h | %h | %h", a, b, result);

        // Test 10: Subtract Denormalized Numbers
        a = 32'h00000001; // Smallest Positive Denormalized Number
        b = 32'h00000001; // Smallest Positive Denormalized Number
        #10;
        $display("10   | %h | %h | %h", a, b, result);

        // Finish simulation
        $display("---------------------------------------------------------");
        $finish;
    end
endmodule

