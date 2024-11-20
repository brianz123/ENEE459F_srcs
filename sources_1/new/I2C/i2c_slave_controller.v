`timescale 1ns / 1ps

module i2c_slave_controller
(
    inout wire sda,
    input wire scl,
    output reg ack,            // ack signal to master
    output reg [7:0] data_out, // data received from master
    input wire [6:0] slave_addr // slave's stored address
);

    localparam IDLE = 0;
    localparam ADDRESS = 1;
    localparam ACKNOWLEDGE = 2;
    localparam RECEIVE_DATA = 3;
    localparam STOP = 4;

    reg [2:0] state = IDLE;
    reg [7:0] shift_reg;
    reg [3:0] bit_count;

    assign sda = (state == ACKNOWLEDGE) ? 1'b0 : 1'bz; // pull SDA low for ACK

    always @(negedge scl) begin
        case (state)
            IDLE: begin
                if (sda == 0) begin //  start
                    state <= ADDRESS;
                    bit_count <= 7; 
                    ack = 0;
                    shift_reg <= 0; // clear shift reg
                end
            end

            ADDRESS: begin
                shift_reg[bit_count] <= sda; // Shift in address bit
                if (bit_count == 0) begin
                    if (shift_reg[7:1] == slave_addr) begin
                        ack <= 1; // Address matches
                        state <= ACKNOWLEDGE; // Move to ACK
                    end else begin
                        state <= STOP; // Address mismatch
                    end
                end else begin
                    bit_count <= bit_count - 1; 
                end
            end

            ACKNOWLEDGE: begin
                // Send ACK
                state <= RECEIVE_DATA; // move to receive data
                bit_count <= 7;
            end

            RECEIVE_DATA: begin
                shift_reg[bit_count] <= sda; // shift in data
                if (bit_count == 0) begin
                    shift_reg = shift_reg + sda;
                    $display("Receiving Data: %b", sda);
                    data_out <= shift_reg; // data fully received
                    state <= STOP; // to STOP state
                end else begin
                    bit_count <= bit_count - 1;
                end
            end

            STOP: begin
                ack <= 0; // Reset ACK 
                $display("END");
//                if (sda == 0) begin // stop 
                    state <= IDLE;
                    
//                end
            end
        endcase
    end

    always @(posedge scl) begin
        if (state == RECEIVE_DATA) begin
            $display("Receiving Data: %b", shift_reg);
        end
    end

endmodule
