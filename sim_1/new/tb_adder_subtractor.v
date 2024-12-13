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

