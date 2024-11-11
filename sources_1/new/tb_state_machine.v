module tb_state_machine;

// Testbench signals
reg clk;
reg reset;
reg [1:0] opcode;
wire done;

// Instantiate the state_machine module
state_machine uut (
    .clk(clk),
    .reset(reset),
    .opcode(opcode),
    .done(done)
);

// Clock generation
initial begin
    clk = 0;
    forever #5 clk = ~clk; // 10ns clock period
end

// Test procedure
initial begin
    // Initialize inputs
    reset = 1;
    opcode = 3'b000;

    // Apply reset
    #10 reset = 0;

    // Test IDLE -> ASK_TASK -> CHOOSE_TASK -> MULTIPLY -> DONE
    #10 opcode = 0; // MULTIPLY opcode
    #40;

    // Test IDLE -> ASK_TASK -> CHOOSE_TASK -> ADD -> DONE
    #10 opcode = 1; // ADD opcode
    #40;

    // Test IDLE -> ASK_TASK -> CHOOSE_TASK -> SUBTRACT -> DONE
    #10 opcode = 2; // SUBTRACT opcode
    #40;

    #20;

    // Finish simulation
    #10 $finish;
end

// Monitor the outputs
initial begin
    $monitor("Time = %0t | State = %0b | Opcode = %0b | Done = %0b", 
              $time, uut.state, opcode, done);
end

endmodule
