// Experimental CRC-16/CCITT-FALSE combinational calculation.
// Polynomial 0x1021, initial value 0xFFFF, no reflection, xorout 0.
// NOT a UCIe normative CRC selection.
module crc16_ccitt #(
    parameter integer DATA_WIDTH = 64
) (
    input wire [DATA_WIDTH-1:0] data,
    output reg [15:0] crc
);
    integer i;
    reg [15:0] c;
    always @* begin
        c = 16'hFFFF;
        for (i=DATA_WIDTH-1; i>=0; i=i-1) begin
            if (c[15] ^ data[i])
                c = {c[14:0],1'b0} ^ 16'h1021;
            else
                c = {c[14:0],1'b0};
        end
        crc = c;
    end
endmodule
