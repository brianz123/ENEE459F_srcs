`timescale 1ns / 1ps

module top_level_i2c
(
    input wire clk,               // System clock
    input wire rst,               // Reset signal
    output reg enable,            // Enable signal for master (now a reg)
    output wire [7:0] led_output, // LED output for displaying received data
    inout wire i2c_sda,          // I2C SDA line
    inout wire i2c_scl           // I2C SCL line
);

    wire [7:0] data_out_master;
    wire ready_master;
    reg [6:0] addr_master = 7'b0101010; // Example slave address
    reg [7:0] data_in_master = 8'hAA; // Example data to send
    reg rw_master = 0;

    i2c_master_controller master (
        .clk(i2c_scl),
        .rst(rst),
        .addr(addr_master),
        .data_in(data_in_master),
        .enable(enable),
        .rw(rw_master),
        .data_out(data_out_master),
        .ready(ready_master),
        .i2c_sda(i2c_sda),
        .i2c_scl(i2c_scl)
    );

    wire ack_slave;
    reg [6:0] slave_addr = 7'b0101010; // Slave address

    i2c_slave_controller slave (
        .sda(i2c_sda),
        .scl(i2c_scl),
        .ack(ack_slave),
        .data_out(led_output),
        .slave_addr(slave_addr)
    );

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            enable <= 0;
        end else if (ready_master) begin
            enable <= 1;
        end else begin
            enable <= 0;
        end
    end

endmodule
