`timescale 1ns / 1ps

module PmodOLEDCtrl(
    input CLK,
    input RST,
    input EN,
    input [3:0] SW, // 4-bit switch input
    output CS,
    output SDIN,
    output SCLK,
    output DC,
    output RES,
    output VBAT,
    output VDD,
    output FIN,
    input rx_irq,
    input tx_irq,
    input [7:0] rx_data,
    input [127:0] reg0,
    input [127:0] reg1, 
    input [127:0] reg2, 
    input [127:0] reg3,
    output [3:0] write_pointer,
    output [3:0] read_pointer


);

	wire CS, SDIN, SCLK, DC;
	wire VDD, VBAT, RES;
	reg[127:0] Page0_reg, Page1_reg, Page2_reg, Page3_reg;
    
	reg [110:0] current_state = "Idle";

	wire init_en;
	wire init_done;
	wire init_cs;
	wire init_sdo;
	wire init_sclk;
	wire init_dc;
	
	wire display_en;
	wire display_cs;
	wire display_sdo;
	wire display_sclk;
	wire display_dc;
	wire display_done;

    wire clk_100MHz;
    wire reset;
    wire clk_1Hz;


    wire clock_Wr;
    wire clock_Rd;
    wire [7:0] tx_data;
    wire Empty_Flag;
    wire Full_Flag;

    wire ascii_hex_data_HI;
    wire ascii_hex_data_LO;


	OledInit Init(
			.CLK(CLK),
			.RST(RST),
			.EN(init_en),
			.CS(init_cs),
			.SDO(init_sdo),
			.SCLK(init_sclk),
			.DC(init_dc),
			.RES(RES),
			.VBAT(VBAT),
			.VDD(VDD),
			.FIN(init_done)
	);
	
	OledEX Display(
			.CLK(CLK),
			.RST(RST),
			.EN(display_en),
			.Page0(Page0_reg),
			.Page1(Page1_reg),
			.Page2(Page2_reg),
			.Page3(Page3_reg),
			.CS(display_cs),
			.SDO(display_sdo),
			.SCLK(display_sclk),
			.DC(display_dc),
			.FIN(display_done)
	);


    clock_divider ClockDivider(
        .clk_100MHz(CLK),
        .reset(RST),
        .clk_1Hz(clk_1Hz)
    );

    FIFO10 FIFO(
        .clock_Wr(clk_1Hz),
        .clock_Rd(clk_1Hz),
        .reset(RST),
        .rx_data(rx_data),
        .rx_irq(rx_irq),
        .tx_irq(tx_irq),
        .tx_data(tx_data),
        .write_pointer(write_pointer),
        .read_pointer(read_pointer),
        .Empty_Flag(Empty_Flag),
        .Full_Flag(Full_Flag)
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


	//MUXes to indicate which outputs are routed out depending on which block is enabled
	assign CS = (current_state == "OledInitialize") ? init_cs : display_cs;
	assign SDIN = (current_state == "OledInitialize") ? init_sdo : display_sdo;
	assign SCLK = (current_state == "OledInitialize") ? init_sclk : display_sclk;
	assign DC = (current_state == "OledInitialize") ? init_dc : display_dc;
	
	//MUXes that enable blocks when in the proper states
	assign init_en = (current_state == "OledInitialize") ? 1'b1 : 1'b0;
	assign display_en = (current_state == "OledDisplay") ? 1'b1 : 1'b0;
	
    //Display finish flag only high when in done state
    assign FIN = (current_state == "Done") ? 1'b1 : 1'b0;
    reg [110:0] current_state = "Idle";

    // State Machine
    always @(posedge CLK) begin
        if (RST == 1'b1) begin
            current_state <= "Idle";
            Page0_reg <= 128'h00000000000000000000000000000000; // Clear display on reset
            Page1_reg <= 128'h00000000000000000000000000000000;
            Page2_reg <= 128'h00000000000000000000000000000000;
            Page3_reg <= 128'h00000000000000000000000000000000;
        end
        else begin
            case(current_state)
                "Idle" : begin
                    current_state <= "OledInitialize";
                end
                "OledInitialize" : begin
                    if(init_done == 1'b1) begin
                        current_state <= "OledReady";
                    end
                end
                
                
                
                "OledReady" : begin
                    if (EN == 1'b1) begin
                        // Display the FIFO output data in hexadecimal
                        // Page0_reg <= SW[0] ? {8'h30, 8'h78, bin_to_ascii_hex(tx_data[7:4]), bin_to_ascii_hex(tx_data[3:0]), 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00} : 128'h0000000000000000;
                        // Page1_reg <= (SW[1] && Empty_Flag) ? 128'h454D50545920464C4147000000000000 : 128'h0000000000000000;
                        // Page2_reg <= (SW[2] && Full_Flag) ? 128'h46554C4C20464C414700000000000000 : 128'h0000000000000000;
                        // Page3_reg <= 128'h0000000000000000;

                        Page0_reg <= reg0;
                        Page1_reg <= reg1;
                        Page2_reg <= reg2;
                        Page3_reg <= reg3;


                        current_state <= "OledDisplay";
                    end
                end
                
                
                
                "OledDisplay" : begin
                    if(display_done == 1'b1) begin
                        current_state <= "Done";
                    end
                end
                "Done" : begin
                    if(EN == 1'b0) begin
                        current_state <= "OledReady";
                    end
                end
                default : current_state <= "Idle";
            endcase
        end
    end
endmodule
