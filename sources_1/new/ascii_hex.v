module ascii_to_hex_string(
    input  [7:0] ascii_char,    // 8-bit input for ASCII character
    output reg [31:0] hex_buf   // Output buffer for "0xHH" format
);
    reg [3:0] high_nibble;
    reg [3:0] low_nibble;

    always @(*) begin
        hex_buf[31:24] = "0";   // ASCII code for '0'
        hex_buf[23:16] = "x";   // ASCII code for 'x'

        high_nibble = ascii_char[7:4];
        low_nibble  = ascii_char[3:0];

        // Convert high nibble to ASCII character
        if (high_nibble > 4'd9)
            hex_buf[15:8] = "a" + (high_nibble - 4'd10);
        else
            hex_buf[15:8] = "0" + high_nibble;

        // Convert low nibble to ASCII character
        if (low_nibble > 4'd9)
            hex_buf[7:0] = "a" + (low_nibble - 4'd10);
        else
            hex_buf[7:0] = "0" + low_nibble;
    end
endmodule
