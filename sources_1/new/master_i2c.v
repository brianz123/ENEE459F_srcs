`timescale 1ns / 1ps

module master_i2c (
    input wire [103:0] master_data_in,
    input wire clk,
    input wire rst,
    input wire enable,
    output wire ready,
    output wire done,
    output reg complete,
    inout wire i2c_sda,
    inout wire i2c_scl
);
    parameter [6:0] address = 7'b0001101;
    reg [7:0] data; // Should be `reg` because it is assigned in an always block
    reg go;         // Used as an enable signal for the i2c_master_controller
    reg rw;         // Read/Write control signal
    reg [7:0] counter; // Counter for data_in indexing
    reg [1:0] state;      // State register
    
    // Instance of the i2c_master_controller
    i2c_master_controller master (
        .clk(clk), 
        .rst(rst), 
        .addr(address), 
        .data_in(data), 
        .enable(go), 
        .rw(rw), 
        .data_out(), // If not used, leave unconnected or specify `data_out` usage
        .ready(ready), 
        .done(done),
        .i2c_sda(i2c_sda), 
        .i2c_scl(i2c_scl)
    );
    parameter IDLE = 2'd0;
    parameter RUN  = 2'd1;
    parameter WAIT = 2'd2;
    parameter DONE = 2'd3;
    // Initialization
    initial begin
        counter = 13'd96;
        state = 0;  
        rw = 0; 
        go = 0;
        complete = 0;
    end
    
    // State machine for data handling and I2C control
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            // Reset logic
            counter <= 13'd96;
            state <= 0;
            go <= 0;
        end else begin
            case (state)
                IDLE: begin
                    // Initial state or waiting for enable
                    complete <= 0;
                    if (enable) begin
                        data <= {master_data_in[counter+7],master_data_in[counter+6],master_data_in[counter+5], master_data_in[counter+4], master_data_in[counter+3], master_data_in[counter+2], master_data_in[counter+1], master_data_in[counter]}; // Load data
                        go <= 1;                 // Trigger I2C transaction
                        state <= 1;              // Move to the next state
                    end
                end
                RUN: begin
                    // Wait for the ready signal
                    if (done) begin
                        go <= 0;              // Disable the transaction
                        counter <= counter - 8;
                        if (counter <= 0 || counter > 115) begin
//                            counter <= 13'd96;     // Reset counter if end of data is reached
                            state = 3;
                        end else begin
                            state = 2;          // Return to the initial state
                        end
                    end
                end
                
                WAIT: begin
                    if(ready) begin
                        state <= 0;
                    end
                
                end
                
                 DONE: begin
                                                   
                       counter <= 13'd96;     // Reset counter if end of data is reached
                       complete <= 1;
                       state <= 0;
                 end
                
                default: state <= 0;          // Default case to avoid latches
            endcase
        end
    end
    
endmodule
