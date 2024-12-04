    `timescale 1ns / 1ps
    //////////////////////////////////////////////////////////////////////////////////
    // Reference Book: FPGA Prototyping By Verilog Examples Xilinx Spartan-3 Version
    // Authored by: Dr. Pong P. Chu
    // Published by: Wiley
    //
    // Adapted for the Basys 3 Artix-7 FPGA by David J. Marion
    //
    // UART System Verification Circuit
    //
    // Comments:
    // - Many of the variable names have been changed for clarity
    //////////////////////////////////////////////////////////////////////////////////
    
    module uart_test(
        input CLK,       // basys 3 FPGA clock signal
        input reset,            // btnR    
        input rx,               // USB-RS232 Rx
        input btn,              // btnL (read and write FIFO operation)
        output tx,              // USB-RS232 Tx
//        output [3:0] an,        // 7 segment display digits
//        output [0:6] seg,       // 7 segment display segments
        output reg finished,        // data byte display
        output reg [65:0] uart_in
        );
        
        // Connection Signals
        wire rx_full, rx_empty;
        wire btn_tick;
        wire [7:0] rec_data, rec_data1;
        
        
        // Complete UART Core
        uart_top UART_UNIT
            (
                .CLK(CLK),
                .RST(reset),
                .read_uart(btn_tick),
                .write_uart(btn_tick),
                .rx(rx),
                .write_data(rec_data1),
                .rx_full(rx_full),
                .rx_empty(rx_empty),
                .read_data(rec_data),
                .tx(tx)
            );
        
        // Button Debouncer
        debounce_explicit BUTTON_DEBOUNCER
            (
                .clk_100MHz(CLK),
                .reset(reset),
                .btn(btn),         
                .db_level(),  
                .db_tick(btn_tick)
            );
        reg [7:0] counter = 0;
        // Signal Logic    
        assign rec_data1 = rec_data;    // add 1 to ascii value of received data (to transmit)
//        reg led = 1;
        // Output Logic
        assign LED = rec_data;              // data byte received displayed on LEDs
//        assign LED[0] = led;
        assign an = 4'b1110;                // using only one 7 segment digit 
        assign seg = {~rx_full, 2'b11, ~rx_empty, 2'b11, full};
        reg full = 1;
//        reg [65:0] uart_in;
        wire data;
        assign data = 
            // Check if rec_data corresponds to ASCII '0'-'9' (0x30-0x39)
            (rec_data >= 8'h30 && rec_data <= 8'h39) ? rec_data - 8'h30 : 
            // Check if rec_data corresponds to ASCII 'A'-'F' (uppercase, 0x41-0x46)
            (rec_data >= 8'h41 && rec_data <= 8'h46) ? rec_data - 8'h37 : 
            // Check if rec_data corresponds to ASCII 'a'-'f' (lowercase, 0x61-0x66)
            (rec_data >= 8'h61 && rec_data <= 8'h66) ? rec_data - 8'h57 : 
            // If rec_data does not match any of the above, set data to undefined (xxxx)
            4'bxxxx;        always @(posedge btn) begin
            if(counter < 66) begin
                uart_in[counter] = data;
                counter = counter+1;
                finished = 0;              
            end else begin
                finished = 1;
            end
        end
        
    endmodule
