// Generic experimental data+CRC envelope, not a UCIe flit encoder.
// Combinational ready/valid passthrough; no buffering or replay.
module integrity_tx #(parameter integer DATA_WIDTH=64)(
 input wire [DATA_WIDTH-1:0] s_data,
 input wire s_valid,
 output wire s_ready,
 output wire [DATA_WIDTH-1:0] m_data,
 output wire [15:0] m_crc,
 output wire m_valid,
 input wire m_ready
);
 crc16_ccitt #(.DATA_WIDTH(DATA_WIDTH)) crc_inst(
  .data(s_data),.crc(m_crc));
 assign m_data=s_data;
 assign m_valid=s_valid;
 assign s_ready=m_ready;
endmodule
