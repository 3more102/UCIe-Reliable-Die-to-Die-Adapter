// Generic CRC-16/CCITT-FALSE combinational calculator.
// Polynomial 0x1021, initial remainder 0xFFFF, no reflection, xorout 0.
// Infrastructure only: NOT a UCIe-defined CRC or flit implementation.
module crc16_ccitt #(
    parameter integer DATA_WIDTH = 64
) (
    input  wire [DATA_WIDTH-1:0] data_i,
    output reg  [15:0]           crc_o
);
    integer i;
    reg feedback;
    always @* begin
        crc_o = 16'hFFFF;
        for (i = DATA_WIDTH-1; i >= 0; i = i-1) begin
            feedback = crc_o[15] ^ data_i[i];
            crc_o = {crc_o[14:0], 1'b0};
            if (feedback)
                crc_o = crc_o ^ 16'h1021;
        end
    end
endmodule
