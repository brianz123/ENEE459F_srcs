// Testbench with comprehensive test cases
module tb_multiplier;
    reg clk, rst;
    reg [31:0] a, b;
    wire [31:0] result;
    wire valid;
    
    integer i;
    real float_a, float_b, float_result;
    
    // Function to convert real to IEEE 754
    function [31:0] real_to_float;
        input real num;
        reg sign;
        reg [7:0] exp;
        reg [22:0] frac;
        real abs_num;
        begin
            if (num < 0) begin
                sign = 1;
                abs_num = -num;
            end else begin
                sign = 0;
                abs_num = num;
            end
            
            exp = 127;
            while (abs_num >= 2.0) begin
                abs_num = abs_num / 2.0;
                exp = exp + 1;
            end
            while (abs_num < 1.0 && exp > 0) begin
                abs_num = abs_num * 2.0;
                exp = exp - 1;
            end
            
            abs_num = abs_num - 1.0;  // Remove hidden 1
            frac = abs_num * 8388608.0; // 2^23
            
            real_to_float = {sign, exp, frac};
        end
    endfunction
    
    // Function to convert IEEE 754 to real
    function real float_to_real;
        input [31:0] float;
        reg sign;
        reg [7:0] exp;
        reg [22:0] frac;
        real result;
        begin
            sign = float[31];
            exp = float[30:23];
            frac = float[22:0];
            
            if (exp == 0) begin
                float_to_real = 0;
            end else if (exp == 255) begin
                float_to_real = 'hFFFFFFFF;
            end else begin
                result = 1.0 + (frac / 8388608.0);  // 2^23
                result = result * (2.0 ** (exp - 127));
                if (sign) result = -result;
                float_to_real = result;
            end
        end
    endfunction
    
    multiplier uut (
        .clk(clk),
        .rst(rst),
        .a(a),
        .b(b),
        .result(result),
        .valid(valid)
    );
    
    initial begin
        clk = 0;
        forever #5 clk = ~clk;
    end
    
    initial begin
        // Initialize
        rst = 1;
        #20 rst = 0;
        
        // Test Case 1: 1.0 * 1.0 = 1.0
        a = real_to_float(1.0);
        b = real_to_float(1.0);
        #20;
        @(posedge valid);
        float_result = float_to_real(result);
        $display("1.0 * 1.0 = %f", float_result);
        
        // Test Case 2: 2.0 * 2.0 = 4.0
        a = real_to_float(2.0);
        b = real_to_float(2.0);
        #20;
        @(posedge valid);
        float_result = float_to_real(result);
        $display("2.0 * 2.0 = %f", float_result);
        
        // Test Case 3: 3.0 * 3.0 = 9.0
        a = real_to_float(3.0);
        b = real_to_float(3.0);
        #20;
        @(posedge valid);
        float_result = float_to_real(result);
        $display("3.0 * 3.0 = %f", float_result);
        
        // Test Case 4: 2.5 * 2.5 = 6.25
        a = real_to_float(2.5);
        b = real_to_float(2.5);
        #20;
        @(posedge valid);
        float_result = float_to_real(result);
        $display("2.5 * 2.5 = %f", float_result);
        
        // Test Case 5: 4.0 * 4.0 = 16.0
        a = real_to_float(1000000.0);
        b = real_to_float(1000000000000.0);
        #20;
        @(posedge valid);
        float_result = float_to_real(result);



        a = real_to_float(-10.0);
        b = real_to_float(-10.0);
        #20;
        @(posedge valid);
        float_result = float_to_real(result);



        a = real_to_float(1000000000.0);
        b = real_to_float(0.00000001);
        #20;
        @(posedge valid);
        float_result = float_to_real(result);
        
        #100 $finish;
    end
    
endmodule

