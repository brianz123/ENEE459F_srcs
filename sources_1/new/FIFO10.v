module FIFO10 (
    input wire clock_100M,
    input wire reset,
    input wire [7:0] rx_data,
    input wire rx_irq,  // Insertion request
    input wire tx_irq,  // Removal request
    output reg [7:0] tx_data,
    output reg Empty_Flag,
    output reg Full_Flag,
    output reg [3:0] write_pointer,
    output reg [3:0] read_pointer,
    input wire [3:0] debug_index,  // Index for inspecting FIFO memory
    output wire [7:0] fifo_debug_data  // Output for the selected memory content
);

    // Define the FIFO storage as a 2D array with 10 slots, each 8 bits wide
    reg [7:0] fifo_mem [0:9];
    reg [3:0] data_count;  // New register to track the number of elements in the FIFO
    integer i;
     reg wait_for_rx_irq_low;
    // Assign the content at the debug_index to the debug output
    assign fifo_debug_data = fifo_mem[debug_index];

    // FIFO initialization and pointer reset
   always @(posedge clock_100M or posedge reset) begin
    if (reset) begin
        write_pointer <= 0;
        read_pointer <= 0;
        Empty_Flag <= 1;
        Full_Flag <= 0;
        wait_for_rx_irq_low <= 1'b0;
    end else begin
        // Write operation
        wait_for_rx_irq_low <= 1'b0;
        if (rx_irq && !Full_Flag && rx_data!=0 && !wait_for_rx_irq_low) begin
            fifo_mem[write_pointer] <= rx_data;
            write_pointer <= (write_pointer + 1) % 10;
            wait_for_rx_irq_low <= 1'b1;
        end else if (!rx_irq) begin
            wait_for_rx_irq_low <= 1'b0; // Exit waiting state when rx_irq is 0
        end
        
                // Read operation
        if (tx_irq && !Empty_Flag) begin
            tx_data <= fifo_mem[read_pointer];
            read_pointer <= (read_pointer + 1) % 10;
        end

        // Update Flags
        Empty_Flag <= (write_pointer == read_pointer) && !rx_irq;
        Full_Flag <= (write_pointer + 1) % 10 == read_pointer;
    end
end


endmodule
