// Experimental stop-and-wait replay slot, NOT UCIe normative retry.
// A single outstanding word is retained until ACK. A retry request re-arms
// the word for retransmission; only an actual ready/valid handshake sends it.
// ack and retry_req must not be asserted together.
module replay_slot #(parameter integer WIDTH=64)(
 input wire clk,rst_n,
 input wire [WIDTH-1:0] s_data,
 input wire s_valid,
 output wire s_ready,
 output wire [WIDTH-1:0] m_data,
 output wire m_valid,
 input wire m_ready,
 input wire ack,
 input wire retry_req,
 output wire outstanding
);
 reg [WIDTH-1:0] data_q;
 reg occupied_q, pending_q;
 assign s_ready=!occupied_q;
 assign outstanding=occupied_q;
 assign m_data=data_q;
 assign m_valid=occupied_q && pending_q;
 always @(posedge clk or negedge rst_n) begin
  if(!rst_n) begin
   data_q<={WIDTH{1'b0}};
   occupied_q<=0;
   pending_q<=0;
  end else if(occupied_q) begin
   if(ack) begin
    occupied_q<=0;
    pending_q<=0;
   end else if(retry_req) begin
    pending_q<=1;
   end else if(m_valid && m_ready) begin
    pending_q<=0;
   end
  end else if(s_valid && s_ready) begin
   data_q<=s_data;
   occupied_q<=1;
   pending_q<=1;
  end
 end
endmodule
