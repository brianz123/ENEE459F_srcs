    `timescale 1ns / 1ps

    module uart_test(
        input CLK,       // basys 3 FPGA clock signal
        input reset,            // btnR    
        input rx,               // USB-RS232 Rx
        input btn,              // btnL (read and write FIFO operation)
        output tx,              // USB-RS232 Tx
        output [3:0] an,        // 7 segment display digits
        output [0:6] seg,       // 7 segment display segments
        output [7:0] LED        // data byte display
        );
        
        // Connection Signals
        wire rx_full, rx_empty, btn_tick, clk_1kHz;
        wire [7:0] rec_data, rec_data1;
        
        // Complete UART Core
    uart_top UART_UNIT
        (
            .CLK(CLK),
            .RST(reset),
            .read_uart(clk_1kHz),
            .write_uart(clk_1kHz),
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
       ClockDivider clkDivide(
               .clk_100MHz(CLK),
               .clk_1kHz(clk_1kHz)
            ); 
        reg [6:0] counter;
        initial begin
            counter = 0;
        end
        
        always @(posedge clk_1kHz or posedge reset) begin
            counter = counter + 1;
            if(counter > 65) begin
                counter = 0;
            end
        
        end    
            
        // Signal Logic    
        assign rec_data1 = rec_data;    // add 1 to ascii value of received data (to transmit)
        
        // Output Logic
        assign LED = rec_data;              // data byte received displayed on LEDs
        assign an = 4'b1110;                // using only one 7 segment digit 
        assign seg = {~rx_full, 2'b11, ~rx_empty, 3'b111};
    endmodule
    
    
    
    
    
    
    
module ClockDivider(
    input clk_100MHz,
    output reg clk_1kHz
);
    reg [26:0] counter = 0; // Enough bits to count to 100M
    initial begin
        clk_1kHz <= 0;
    end
    
    always @(posedge clk_100MHz) begin
        if (counter == 5000 - 1) begin
            clk_1kHz <= ~clk_1kHz;
            counter <= 0;
        end else begin
            counter <= counter + 1;
        end
    end
endmodule
