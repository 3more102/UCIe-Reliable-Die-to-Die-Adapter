// Generic experimental stop-and-wait receiver; NOT UCIe protocol RTL.
// A CRC-valid duplicate is acknowledged but is not delivered twice.
module experimental_stopwait_rx #(parameter integer DATA_WIDTH=32)(
 input wire clk,rst_n,
 input wire [DATA_WIDTH+16:0] frame_data,
 input wire frame_valid,output wire frame_ready,
 output wire [DATA_WIDTH-1:0] m_data,
 output wire m_valid,input wire m_ready,
 output reg ack_valid,ack_seq,ack_ok,
 output reg [31:0] crc_error_count
);
 reg [DATA_WIDTH-1:0] output_q;
 reg output_valid_q,expected_seq_q;
 wire rx_seq=frame_data[DATA_WIDTH+16];
 wire [DATA_WIDTH-1:0] rx_payload=frame_data[DATA_WIDTH+15:16];
 wire [15:0] rx_crc=frame_data[15:0];
 wire [15:0] calculated_crc;
 wire crc_ok=(rx_crc==calculated_crc);
 wire take_frame=frame_valid && frame_ready;
 crc16_ccitt #(.DATA_WIDTH(DATA_WIDTH+1)) crc_check(
  .data_i({rx_seq,rx_payload}),.crc_o(calculated_crc)
 );
 assign m_data=output_q;
 assign m_valid=output_valid_q;
 assign frame_ready=!output_valid_q || m_ready;
 always @(posedge clk or negedge rst_n) begin
  if(!rst_n) begin
   output_q<=0;output_valid_q<=0;expected_seq_q<=0;
   ack_valid<=0;ack_seq<=0;ack_ok<=0;crc_error_count<=0;
  end else begin
   ack_valid<=0;
   if(frame_ready) begin
    if(output_valid_q && m_ready) output_valid_q<=0;
    if(take_frame) begin
     ack_valid<=1;ack_seq<=rx_seq;ack_ok<=crc_ok;
     if(!crc_ok) crc_error_count<=crc_error_count+1'b1;
     else if(rx_seq==expected_seq_q) begin
      output_q<=rx_payload;output_valid_q<=1;
      expected_seq_q<=~expected_seq_q;
     end
    end
   end
  end
 end
endmodule
