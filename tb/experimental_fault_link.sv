// Simulation-only digital fault model; NOT a PHY or UCIe link.
module experimental_fault_link #(
 parameter integer FRAME_WIDTH=49,
 parameter integer CORRUPT_BIT=0
)(
 input wire clk,rst_n,enable_single_fault,
 input wire [FRAME_WIDTH-1:0] s_data,
 input wire s_valid,output wire s_ready,
 output wire [FRAME_WIDTH-1:0] m_data,
 output wire m_valid,input wire m_ready,
 output reg [31:0] fault_count
);
 reg corrupted_once_q;
 wire corrupt_this=enable_single_fault && !corrupted_once_q;
 wire [FRAME_WIDTH-1:0] mask=
  {{(FRAME_WIDTH-1){1'b0}},1'b1}<<CORRUPT_BIT;
 assign s_ready=m_ready;
 assign m_valid=s_valid;
 assign m_data=s_data ^ (corrupt_this ? mask : {FRAME_WIDTH{1'b0}});
 always @(posedge clk or negedge rst_n) begin
  if(!rst_n) begin corrupted_once_q<=0;fault_count<=0; end
  else if(s_valid && s_ready && corrupt_this) begin
   corrupted_once_q<=1;
   fault_count<=fault_count+1'b1;
  end
 end
endmodule
