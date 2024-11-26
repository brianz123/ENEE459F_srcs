`timescale 1ns / 1ps

module fpga_b_top_tb;
    reg clk;
    reg rst;
    reg [103:0] i2c_in;

    // inout wire sda,
    // input wire scl,
    // input [1:0] mode,
    
    wire CS;
    wire SDIN;
    wire SCLK;
    wire DC;
    wire RES;
    wire VBAT;
    wire VDD;
    wire FIN;

    reg sda;
    reg scl;
    reg [1:0] mode;
    
    // Clock generation parameters
    parameter CLOCK_PERIOD = 10;  // 100MHz clock
    
    // IEEE-754 Single Precision Test Values
    // 32'h3F800000 = 1.0
    // 32'h40000000 = 2.0
    // 32'h40400000 = 3.0
    // 32'h40800000 = 4.0
    // 32'h3F000000 = 0.5
    // 32'hBF800000 = -1.0
    // 32'h00000000 = 0.0
    // 32'h7F800000 = Infinity
    
    // Instantiate the DUT (Design Under Test)
    fpga_b_top DUT (
        .clk(clk),
        .rst(rst),
        .i2c_in(i2c_in),
        .CS(CS),
        .SDIN(SDIN),
        .SCLK(SCLK),
        .DC(DC),
        .RES(RES),
        .VBAT(VBAT),
        .VDD(VDD),
        .FIN(FIN)
    );

    wire multiplied_valid;
    wire [31:0] product;
    wire [31:0] ans;
    wire [1:0] current_state;
    wire [1:0] next_state;
    wire [31:0] operand_a;
    wire [31:0] operand_b;
    wire [1:0] operation;
    wire en;
    wire [127:0] line0_reg;
    wire [127:0] line1_reg;
    

    assign multiplied_valid = DUT.multiplied_valid;
    assign product = DUT.product;
    assign ans = DUT.ans;
    assign current_state = DUT.current_state;
    assign next_state = DUT.next_state;
    assign operand_a = DUT.operand_a;
    assign operand_b = DUT.operand_b;
    assign operation = DUT.operation;
    assign en = DUT.en;
    assign line0_reg = DUT.line0_reg;
    assign line1_reg = DUT.line1_reg;
    
    // Clock generation
    always begin
        clk = 1'b0;
        #(CLOCK_PERIOD/2);
        clk = 1'b1;
        #(CLOCK_PERIOD/2);
    end
    
    // Test stimulus
    initial begin
        // Initialize all inputs
        rst = 1'b1;
        i2c_in = 104'b0;
        
        $display("Starting testbench");
        
        // Wait 100ns for global reset
        #100;
        rst = 1'b0;
        
        // Test Case 1: 2.0 * 3.0 = 6.0
        #100;
        $display("\nTest Case 1: 2.0 * 2.0");
        i2c_in = {6'b000000, 2'b10, 32'h40400000, 32'h40400000, 32'h40400000};  // op = 10 (multiply), 3.0 * 2.0
        #100;
        
        // Test Case 2: Multiplication by zero
        #200;
        $display("\nTest Case 2: 2.0 * 0.0");
        i2c_in = {6'b000000, 2'b10, 32'h00000000, 32'h40000000, 32'h40400000};  // op = 10 (multiply), 0.0 * 2.0
        #100;
        
        // Test Case 3: Negative number multiplication (-1.0 * 2.0 = -2.0)
        #200;
        $display("\nTest Case 3: -1.0 * 2.0");
        i2c_in = {6'b000000, 2'b10, 32'h40000000, 32'hBF800000, 32'h40400000};  // op = 10 (multiply), 2.0 * -1.0
        #100;
        
        // Test Case 4: Fractional multiplication (0.5 * 4.0 = 2.0)
        #200;
        $display("\nTest Case 4: 0.5 * 4.0");
        i2c_in = {6'b000000, 2'b10, 32'h40800000, 32'h3F000000, 32'h40400000};  // op = 10 (multiply), 4.0 * 0.5
        #100;
        
        // Test Case 5: Small number multiplication (0.5 * 0.5 = 0.25)
        #200;
        $display("\nTest Case 5: 0.5 * 0.5");
        i2c_in = {6'b000000, 2'b10, 32'h3F000000, 32'h3F000000, 32'h40400000};  // op = 10 (multiply), 0.5 * 0.5
        #100;


        #200;
        i2c_in = {6'b000000, 2'b00, 32'h3F000000, 32'h3F000000, 32'h40400000};  // op = 10 (multiply), 0.5 * 0.5
        #100;
        
        // End simulation
        #200;
        $display("\nTestbench completed");
        $finish;
    end
    
    initial begin
        $monitor("Time=%0t rst=%b state=%b valid=%b product=%h",
                 $time, rst, DUT.current_state, DUT.multiplied_valid, DUT.product);
    end
    
    always @(posedge clk) begin
        if (DUT.multiplied_valid) begin
            case (DUT.current_state)
                2'b01: begin  // MULTIPLY state
                    $display("Multiplication operation at time %0t:", $time);
                    $display("Operand A (hex): %h", DUT.operand_a);
                    $display("Operand B (hex): %h", DUT.operand_b);
                    $display("Result (hex): %h", DUT.product);
                    $display("-------------------");
                end
            endcase
        end
    end

endmodule