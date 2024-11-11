FPGA A State machine for top module:
1. Idle
2. Ask user for task (opcode)
3. choose task
4. Multiply
5. Add
6. Subtract
7. Read i2c
8. Write i2c
9. Done

FPGA B State machine for top module:
1. Idle/wait for ack start
2. Choose if you need to multiply
3. Multiply'
4. Round
5. Send to OLED
6. Done

i2c data order flow
ack start -->opcode --> A --> B --> SUM --> ack stop

OPCODES:
00 - ADD
01 - SUB
10 - MULT

// State encoding
parameter IDLE        = 4'b0000;
parameter ASK_TASK    = 4'b0001;
parameter CHOOSE_TASK = 4'b0010;
parameter MULTIPLY    = 4'b0011;
parameter ADD         = 4'b0100;
parameter SUBTRACT    = 4'b0101;
parameter READ_I2C    = 4'b0110;
parameter WRITE_I2C   = 4'b0111;
parameter DONE_STATE  = 4'b1000;