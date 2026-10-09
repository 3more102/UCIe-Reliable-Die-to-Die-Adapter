// Generic combinational CRC word checker for an experimental word format.
// This block is NOT a UCIe flit decoder or a normative UCIe CRC checker.
module crc16_guard #(
    parameter integer DATA_WIDTH = 64
) (
    input wire [DATA_WIDTH-1:0] data,
    input wire [15:0] received_crc,
    output wire [15:0] computed_crc,
    output wire crc_ok
);
    crc16_ccitt #(.DATA_WIDTH(DATA_WIDTH)) crc_calc (
        .data(data), .crc(computed_crc)
    );
    assign crc_ok = (computed_crc == received_crc);
endmodule
