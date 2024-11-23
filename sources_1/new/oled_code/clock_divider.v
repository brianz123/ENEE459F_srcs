`timescale 1ns / 1ps

module clock_divider (
    input wire clk_100MHz,
    input wire reset,
    output reg clk_1Hz
);

    // For 100MHz to 1Hz, we need to divide by 50M to get a full period
    // log2(50M) = 26 bits needed
    reg [25:0] counter;
    
    always @(posedge clk_100MHz or posedge reset) begin
        if (reset) begin
            counter <= 26'd0;
            clk_1Hz <= 1'b0;
        end
        else begin
            if (counter == 26'd49999999) begin  // 50M - 1
                counter <= 26'd0;
                clk_1Hz <= ~clk_1Hz;
            end
            else begin
                counter <= counter + 1'b1;
            end
        end
    end

endmodule