`timescale 1ns / 1ps

module FIFO10 (
    input wire clock_Wr,
    input wire clock_Rd,
    input wire reset,
    input wire [7:0] rx_data,
    input wire rx_irq,
    input wire tx_irq,
    output reg [7:0] tx_data,
    output reg [3:0] write_pointer,
    output reg [3:0] read_pointer,
    output wire Empty_Flag,
    output wire Full_Flag
    // ,
    // output wire [7:0] mem_slot0,
    // output wire [7:0] mem_slot1,
    // output wire [7:0] mem_slot2,
    // output wire [7:0] mem_slot3,
    // output wire [7:0] mem_slot4,
    // output wire [7:0] mem_slot5,
    // output wire [7:0] mem_slot6,
    // output wire [7:0] mem_slot7,
    // output wire [7:0] mem_slot8,
    // output wire [7:0] mem_slot9
);

    // FIFO array, 10 slots, 8-bit wide
    // 1 additional space to account for wraparound pointer logic, FIFO holds max 10 values
    reg [7:0] fifo [0:10];

    // assign mem_slot0 = fifo[0];
    // assign mem_slot1 = fifo[1];
    // assign mem_slot2 = fifo[2];
    // assign mem_slot3 = fifo[3];
    // assign mem_slot4 = fifo[4];
    // assign mem_slot5 = fifo[5];
    // assign mem_slot6 = fifo[6];
    // assign mem_slot7 = fifo[7];
    // assign mem_slot8 = fifo[8];
    // assign mem_slot9 = fifo[9];
    
    wire [3:0] write_pointer_next;
    wire [3:0] read_pointer_next;
    assign write_pointer_next = (write_pointer + 4'd1) % 4'd11;
    assign read_pointer_next = (read_pointer + 4'd1) % 4'd11;


    assign Empty_Flag = (write_pointer == read_pointer);
    assign Full_Flag = (write_pointer_next == read_pointer);




    // Write data
    always @(posedge clock_Wr or posedge reset) begin
        if (reset) begin
            write_pointer <= 4'd0;
        end
        else if (rx_irq && !Full_Flag) begin
            fifo[write_pointer] <= rx_data;
            write_pointer <= write_pointer_next;
        end
    end

    // Read data
    always @(posedge clock_Rd or posedge reset) begin
        if (reset) begin
            read_pointer <= 4'd0;
        end
        else if (tx_irq && !Empty_Flag) begin
            tx_data <= fifo[read_pointer];
            read_pointer <= read_pointer_next;

        end
    end



    // integer i;
    // always @(posedge reset) begin
    //     if (reset) begin
    //         write_pointer <= 4'd0;
    //         read_pointer <= 4'd0;
            
    //         // for (i = 0; i < 10; i = i + 1) begin
    //         //     fifo[i] <= 8'd0;
    //         // end
    //         // tx_data <= 8'd0;
    //     end
    // end

endmodule