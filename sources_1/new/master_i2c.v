`timescale 1ns / 1ps

module master_i2c (
    input wire [103:0] master_data_in, // A wide input bus of 104 bits containing the data to be sent over I2C
    input wire clk,                    // System clock
    input wire rst,                    // Active-high reset
    input wire enable,                 // Enable signal to start I2C operations
    input [8:0] d,                     // Debug or auxiliary data input
    output wire ready,                 // Indicates that the I2C controller is ready for the next operation
    output wire done,                  // Indicates that the I2C transaction has completed
    output reg complete,               // Flag set when the entire data sequence has been transmitted
    output [8:0] debugWire,            // Debug output to observe internal signals
    inout wire i2c_sda,                // I2C data line (bidirectional)
    inout wire i2c_scl                 // I2C clock line (bidirectional)
);
    parameter [6:0] address = 7'b0000111; // I2C slave address to communicate with

    reg [7:0] data;       // Holds the 8-bit chunk of data currently being sent to the I2C controller
    reg go;               // Control signal to initiate an I2C transaction in the i2c_master_controller
    reg rw;               // Read/Write signal (0 for write, 1 for read) for the I2C operation
    reg [7:0] counter;    // Used to track which byte of master_data_in is being sent
    reg [1:0] state;      // State machine register to manage I2C transfer sequences

    // Instantiate the low-level I2C master controller
    i2c_master_controller master (
        .clk(clk),
        .rst(rst),
        .addr(address),
        .data_in(data),
        .enable(go),
        .rw(rw),
        .data_out(),    // Not connected since we are focusing on writes here
        .ready(ready),
        .done(done),
        .i2c_sda(i2c_sda),
        .i2c_scl(i2c_scl)
    );

    assign debugWire[0] = go; // Just a debug signal to observe when 'go' is asserted

    // State encoding for the state machine controlling I2C operations
    parameter IDLE = 2'd0;
    parameter RUN  = 2'd1;
    parameter WAIT = 2'd2;
    parameter DONE = 2'd3;
    
    parameter delay = 100; // Delay parameter used in WAIT state
    reg [10:0] cnt2;       // Counter for timing delays
    reg [10:0] c = 10'd40; // An alternative index or offset (not fully utilized here)

    // Initialization block
    initial begin
        counter = 13'd96;              // Start with a certain byte offset in master_data_in
        state = 0;                     // Initial state is IDLE
        rw = 0;                        // Default to write mode
        go = 0;                        // Not initiating any transaction yet
        complete = 0;                  // Not complete at the start
        cnt2 = 0;                      // No delay count at start
        data = {8'b111111, master_data_in[103:102]}; // Initial data load (partially from master_data_in)
    end
    
    // Main state machine controlling data sequencing and I2C interaction
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            // On reset, reinitialize critical signals
            state <= IDLE;
            go <= 0;
            data <= {6'b111111, master_data_in[103:102]};
        end else begin
            case (state)
                IDLE: begin
                    // Waiting for 'enable' to start sending data
                    complete = 0;
                    if (enable) begin
                        // Load the next 8-bit chunk from master_data_in into 'data'
                        // This slicing takes a byte starting at 'counter' and going through 'counter+7'
                        data <= {master_data_in[counter+7],master_data_in[counter+6],
                                 master_data_in[counter+5],master_data_in[counter+4],
                                 master_data_in[counter+3],master_data_in[counter+2],
                                 master_data_in[counter+1],master_data_in[counter]};
                                 
                        go <= 1;     // Assert 'go' to tell i2c_master_controller to start
                        state <= RUN; // Move to RUN state to wait for the operation to complete
                    end
                end

                RUN: begin
                    // The RUN state waits for the done signal from i2c_master_controller
                    if (done) begin
                        go = 0;        // Clear go once operation is done
                        counter <= counter - 8; // Move to the next byte in master_data_in
                        
                        // Check if we have sent all data or reached an invalid index
                        if (counter < 0 || counter > 115) begin
                            // No more data to send or out of range, go to DONE state
                            state <= DONE;
                        end else begin
                            // Still have data to send, go to WAIT to re-sync or delay
                            state <= WAIT;
                        end
                    end
                end

                WAIT: begin
                    // The WAIT state adds some delay before going back to IDLE to send the next byte
                    if (ready && cnt2 > delay) begin
                        state <= IDLE; // Once ready and delay passed, move back to IDLE
                        cnt2 <= 0;
                    end
                    cnt2 = cnt2 + 1; // Increment delay counter
                end

                DONE: begin
                    // DONE state indicates the entire sequence has been sent
                    counter <= 13'd96;  // Reset counter back to starting position
                    complete <= 1;      // Set complete flag
                    state = IDLE;       // Return to IDLE for future operations
                end

                default: begin
                    // Default case: if state machine is ever out of known states, reset to IDLE
                    state <= IDLE;
                end
            endcase
        end
    end
endmodule
