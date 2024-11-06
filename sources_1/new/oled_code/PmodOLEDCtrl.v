`timescale 1ns / 1ps

module PmodOLEDCtrl(
    input CLK,
    input RST,
    input EN,
    input [3:0] SW,     // 4-bit switch input
    input rx,           // USB-RS232 Rx
    input btn,          // btnL (read/write FIFO operation)
    input remove_btn,
    output tx,          // USB-RS232 Tx
    output CS,
    output SDIN,
    output SCLK,
    output DC,
    output RES,
    output VBAT,
    output VDD,
    output FIN,
    output [7:0] LED,   // Data byte display from UART
    output [3:0] an,    // 7-segment display digits
    output [0:6] seg,    // 7-segment display segments
    output LED15,
    output [7:0] JA
);

    // Connection Signals


    wire clk_1Hz;
    
    ClockDivider clkDivide(
    .clk_100MHz(CLK),
    .clk_1Hz(clk_1Hz)
);
    // Complete UART Core
    uart_top UART_UNIT (
        .CLK(CLK),
        .RST(RST),
        .read_uart(btn_tick),
        .write_uart(btn_tick),
        .rx(rx),
        .write_data(rec_data1),
        .rx_full(rx_full),
        .rx_empty(rx_empty),
        .read_data(rec_data),
        .tx(tx),
        .read_pointer(),  
	    .write_pointer() 
    );
     assign rec_data1 = rec_data;    // add 1 to ascii value of received data (to transmit)

    // Button Debouncer
    debounce_explicit BUTTON_DEBOUNCER (
        .clk_100MHz(CLK),
        .reset(RST),
        .btn(btn),         
        .db_level(),  
        .db_tick(btn_tick)
    );

    // Signal Logic    
//    assign LED = rec_data;       // Display received byte on LEDs
    assign an = 4'b1110;         // Use one 7-segment digit
    assign seg = {~rx_full, 2'b11, ~rx_empty, 3'b111}; // Indicate FIFO status
    
    // FIFO Signals
    wire Empty_Flag, Full_Flag;
    
    // OLED Display Signals
    wire init_en, init_done, init_cs, init_sdo, init_sclk, init_dc;
    wire display_en, display_cs, display_sdo, display_sclk, display_dc, display_done;

    // Registers for OLED pages
    reg [7:0] Page0_reg [0:15]; // Array of bytes for Page0
    reg [127:0] Page1_reg, Page2_reg, Page3_reg;
    reg [110:0] current_state = "Idle";

    // Control signal to read from FIFO
    reg fifo_read_en;

    // Define text for each page
    localparam [127:0] PAGE1_TEXT = "0123456789     "; // Adjusted text
    localparam [127:0] PAGE2_TEXT = "By Brian       "; // Updated text
    localparam [127:0] PAGE3_TEXT = "Success!!      "; // Updated text

    // Instantiate OLED Initialization and Display modules
    OledInit Init (
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

    OledEX Display (
        .CLK(CLK),
        .RST(RST),
        .EN(display_en),
        .Page0({Page0_reg[15], Page0_reg[14], Page0_reg[13], Page0_reg[12],
                Page0_reg[11], Page0_reg[10], Page0_reg[9],  Page0_reg[8],
                Page0_reg[7],  Page0_reg[6],  Page0_reg[5],  Page0_reg[4],
                Page0_reg[3],  Page0_reg[2],  Page0_reg[1],  Page0_reg[0]}),
        .Page1(Page1_reg),
        .Page2(Page2_reg),
        .Page3(Page3_reg),
        .CS(display_cs),
        .SDO(display_sdo),
        .SCLK(display_sclk),
        .DC(display_dc),
        .FIN(display_done)
    );

FIFO10 fifo10 (
        .clock_100M(clk_1Hz),
        .reset(RST),
        .rx_data(rec_data),
        .rx_irq(EN),
        .tx_irq(remove_btn),
        .tx_data(tx_data),
        .Empty_Flag(Empty_Flag),
        .Full_Flag(Full_Flag),
        .write_pointer(write_pointer),
        .read_pointer(read_pointer),
        .debug_index(),
        .fifo_debug_data()
    );   
    wire [31:0] hex_buf;
    ascii_to_hex_string ascii_hex (
        .ascii_char(tx_data),
        .hex_buf(hex_buf)
    );
    
    
    wire rx_full, rx_empty, btn_tick;
    wire [7:0] tx_data, uart_data, rx_data, rec_data1, rec_data;
    wire [3:0] read_pointer,write_pointer;
    assign LED[3:0] = write_pointer;
    assign LED[7:4] = read_pointer;
    assign JA = tx_data;
//assign LED[7] = Empty_Flag;
//assign LED[6] = Full_Flag;


    // MUXes to control output signals based on state
    assign CS = (current_state == "OledInitialize") ? init_cs : display_cs;
    assign SDIN = (current_state == "OledInitialize") ? init_sdo : display_sdo;
    assign SCLK = (current_state == "OledInitialize") ? init_sclk : display_sclk;
    assign DC = (current_state == "OledInitialize") ? init_dc : display_dc;

    // Enable blocks based on states
    assign init_en = (current_state == "OledInitialize") ? 1'b1 : 1'b0;
    assign display_en = (current_state == "OledDisplay") ? 1'b1 : 1'b0;
    //assign 1Hz clk to led15
    assign LED15 = clk_1Hz;
    
    // Display finish flag only high when in done state
    assign FIN = (current_state == "Done") ? 1'b1 : 1'b0;
integer i;
    // State Machine for OLED control
    always @(posedge CLK) begin
        if (RST) begin
            current_state <= "Idle";
            Page1_reg <= 128'h00000000000000000000000000000000;
            Page2_reg <= 128'h00000000000000000000000000000000;
            Page3_reg <= 128'h00000000000000000000000000000000;
            
            for (i = 0; i < 16; i = i + 1) begin
                Page0_reg[15-i] <= 8'h20; // Initialize Page0 with spaces
            end
        end else begin
            case (current_state)
                "Idle" : begin
                    current_state <= "OledInitialize";
                end
                "OledInitialize" : begin
                    if (init_done) begin
                        current_state <= "OledReady";
                    end
                end
                "OledReady" : begin
//                    if (!Empty_Flag) begin
                        // Read data from FIFO and update OLED pages
                        Page0_reg[15-read_pointer] <=  SW[0] ? tx_data : byte_to_ascii(tx_data); // Display FIFO data on Page0
                        Page1_reg <= SW[1] ? PAGE1_TEXT : rec_data;
                        Page2_reg <= SW[2] ?  PAGE1_TEXT : hex_buf;
                        Page3_reg <= SW[3] ? PAGE3_TEXT : 128'h00000000000000000000000000000000;
                        current_state <= "OledDisplay";
//                    end
                end
                "OledDisplay" : begin
                    if (display_done) begin
                        current_state <= "Done";
                    end
                end
                "Done" : begin
                    if (!EN) begin
                        current_state <= "OledReady";
                    end else if (!Empty_Flag) begin
                        current_state <= "OledReady"; // Continue displaying if FIFO not empty
                    end
                end
                default : current_state <= "Idle";
            endcase
        end
    end

endmodule


module ClockDivider(
    input clk_100MHz,
    output reg clk_1Hz
);
    reg [26:0] counter = 0; // Enough bits to count to 100M

    always @(posedge clk_100MHz) begin
        if (counter == 100_000_000 - 1) begin
            clk_1Hz <= ~clk_1Hz;
            counter <= 0;
        end else begin
            counter <= counter + 1;
        end
    end
endmodule
function [7:0] byte_to_ascii;
    input [7:0] byte;  // 8-bit input number representing a full ASCII range
    begin
        // Numbers 0-9
        if (byte >= 8'd0 && byte <= 8'd9)
            byte_to_ascii = "0" + byte;
        
        // Uppercase letters A-Z
        else if (byte >= 8'd10 && byte <= 8'd35)
            byte_to_ascii = "A" + (byte - 8'd10);
        
        // Lowercase letters a-z
        else if (byte >= 8'd36 && byte <= 8'd61)
            byte_to_ascii = "a" + (byte - 8'd36);
        
        // Default case for unsupported values
        else
            byte_to_ascii = "?";
    end
endfunction