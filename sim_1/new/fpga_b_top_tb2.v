`timescale 1ns / 1ps

module fpga_b_top_tb2;
    reg clk;
    reg rst;
    // reg [103:0] i2c_in;
    // wire CS;
    // wire SDIN;
    // wire SCLK;
    // wire DC;
    // wire RES;
    // wire VBAT;
    // wire VDD;
    // wire FIN;

    reg [6:0] addr;
    reg [7:0] data_in;
    reg rw;
	reg enable;
    wire ready;

    wire i2c_sda;
    wire i2c_scl;
    // reg [1:0] mode;

    wire [7:0] received_data;
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


    i2c_master_controller master (
		.clk(clk), 
		.rst(rst), 
		.addr(addr), 
		.data_in(data_in), 
		.enable(enable), 
		.rw(rw), 
		.data_out(data_out), 
		.ready(ready), 
		.i2c_sda(i2c_sda), 
		.i2c_scl(i2c_scl)
	);
    
    // Instantiate the DUT (Design Under Test)
    fpga_b_top DUT (
        .clk(clk),
        .rst(rst),
        // .i2c_in(i2c_in),
        .received_data(received_data),
        .sda(i2c_sda),
        .scl(i2c_scl)
        // .CS(CS),
        // .SDIN(SDIN),
        // .SCLK(SCLK),
        // .DC(DC),
        // .RES(RES),
        // .VBAT(VBAT),
        // .VDD(VDD),
        // .FIN(FIN)
    );
    


    // wire [3:0] byte_counter;
    // wire [2:0] current_state;
    wire [103:0] i2c_in;
    wire new_byte_received;
    wire transmission_complete;
    wire [31:0] ans;
    wire [31:0] mult_a;
    wire [31:0] mult_b;
    wire [31:0] product;
    wire [127:0] line0_reg;
    wire [127:0] line1_reg;
    wire [127:0] line2_reg;
    wire [127:0] line3_reg;
    // assign byte_counter = DUT.byte_counter;
    // assign current_state = DUT.current_state;
    assign i2c_in = DUT.i2c_in;
    assign new_byte_received = DUT.new_byte_received;
    assign transmission_complete = DUT.transmission_complete;
    assign ans = DUT.ans;
    assign mult_a = DUT.mult_a;
    assign mult_b = DUT.mult_b;
    assign product = DUT.product;
    assign line0_reg = DUT.line0_reg;
    assign line1_reg = DUT.line1_reg;
    assign line2_reg = DUT.line2_reg;
    assign line3_reg = DUT.line3_reg;
    
    // Clock generation
    // always begin
    //     clk = 1'b0;
    //     #(CLOCK_PERIOD/2);
    //     clk = 1'b1;
    //     #(CLOCK_PERIOD/2);
    // end

    initial begin
		clk = 0;
		forever begin
			clk = #1 ~clk;
		end		
	end
    

    // Test using i2c input
    initial begin
		clk = 0;
		rst = 1;

		#100;
		rst = 0;
		
		addr = 7'b0000111; // match slaves stored address
		data_in = 8'd6;
		rw = 0;
		enable = 1;
		#10;
		enable = 0; 
		// Increment data_in and send multiple transactions
		// repeat (100) begin
            
		// 	wait(ready)
		// 	data_in = data_in +1; // Increment data_in by 1
		// 	enable = 1;
		// 	#10;
		// 	enable = 0;
			
		// 	#60;
		// end


        // i2c IN 13 bytes
        wait(ready);
        data_in = 8'b11111110; //start byte + mul op
        enable = 1;
        #10;
        enable = 0;

        // operand A = 32'h40 40 00 00
        wait(ready);
        data_in = 8'b00100000;
        enable = 1;
        #10;
        enable = 0;

        wait(ready);
        data_in = 8'b00100000;
        enable = 1;
        #10;
        enable = 0;

        wait(ready);
        data_in = 8'b00000000;
        enable = 1;
        #10;
        enable = 0;

        wait(ready);
        data_in = 8'b00000000;
        enable = 1;
        #10;
        enable = 0;


        // operand B = 32'h 3F 00 00 00 (4)
        wait(ready);
        data_in = 8'b00111111;
        enable = 1;
        #10;
        enable = 0;

        wait(ready);
        data_in = 8'b00000000;
        enable = 1;
        #10;
        enable = 0;

        wait(ready);
        data_in = 8'b00000000;
        enable = 1;
        #10;
        enable = 0;

        wait(ready);
        data_in = 8'b00000000;
        enable = 1;
        #10;
        enable = 0;


        // ans = 32'h 40 80 00 00 => 4
        wait(ready);
        data_in = 8'b01000000;
        enable = 1;
        #10;
        enable = 0;

        wait(ready);
        data_in = 8'b10000000;
        enable = 1;
        #10;
        enable = 0;

        wait(ready);
        data_in = 8'b00000000;
        enable = 1;
        #10;
        enable = 0;

        wait(ready);
        data_in = 8'b00000000;
        enable = 1;
        #10;
        enable = 0;
        




		#500
        // SENDING WITHOUT START BYTE
        wait(ready);
        data_in = 8'b11110000;
        enable = 1;
        #10;
        enable = 0;


        wait(ready);
        data_in = 8'b00001111;
        enable = 1;
        #10;
        enable = 0;


        // START BYTE
        wait(ready);
        data_in = 8'b11111100;
        enable = 1;
        #10;
        enable = 0;

		$finish;
	end  

endmodule