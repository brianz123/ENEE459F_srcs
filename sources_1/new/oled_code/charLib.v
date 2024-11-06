`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 02/25/2020 06:25:56 AM
// Design Name: 
// Module Name: charLib
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module charLib(
    input clka,
    input [10:0] addra,
    output [7:0] douta
    );
    
    BRAM inst(
    .BRAM_PORTA_0_addr(addra),
    .BRAM_PORTA_0_clk(clka),
    .BRAM_PORTA_0_din(8'b0),
    .BRAM_PORTA_0_dout(douta),
    .BRAM_PORTA_0_we());
    
endmodule
