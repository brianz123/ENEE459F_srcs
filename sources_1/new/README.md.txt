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