// Generic experimental stop-and-wait ARQ transmitter; NOT UCIe protocol RTL.
// CRC16_CCITT is a teaching placeholder, NOT the UCIe CRC.
module experimental_stopwait_tx #(parameter integer DATA_WIDTH=32)(
 input wire clk,rst_n,
 input wire [DATA_WIDTH-1:0] s_data,
 input wire s_valid, output wire s_ready,
 output wire [DATA_WIDTH+16:0] frame_data,
 output wire frame_valid,input wire frame_ready,
 input wire ack_valid,ack_seq,ack_ok,
 output reg [31:0] retry_count,output wire pending
);
 reg [DATA_WIDTH-1:0] payload_q;
 reg seq_q,next_seq_q,pending_q,waiting_ack_q;
 wire [15:0] crc;
 crc16_ccitt #(.DATA_WIDTH(DATA_WIDTH+1)) crc_gen(
  .data_i({seq_q,payload_q}),.crc_o(crc)
 );
 assign s_ready=!pending_q;
 assign pending=pending_q;
 assign frame_valid=pending_q && !waiting_ack_q;
 assign frame_data={seq_q,payload_q,crc};
 always @(posedge clk or negedge rst_n) begin
  if(!rst_n) begin
   payload_q<=0;seq_q<=0;next_seq_q<=0;pending_q<=0;
   waiting_ack_q<=0;retry_count<=0;
  end else if (!pending_q) begin
   if(s_valid && s_ready) begin
    payload_q<=s_data;seq_q<=next_seq_q;
    pending_q<=1;waiting_ack_q<=0;
   end
  end else if(!waiting_ack_q) begin
   if(frame_valid && frame_ready) waiting_ack_q<=1;
  end else if(ack_valid && ack_seq==seq_q) begin
   if(ack_ok) begin
    pending_q<=0;waiting_ack_q<=0;next_seq_q<=~seq_q;
   end else begin
    waiting_ack_q<=0;retry_count<=retry_count+1'b1;
   end
  end
 end
endmodule
