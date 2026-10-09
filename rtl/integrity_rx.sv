// Generic one-beat receive-side CRC filter, NOT normative UCIe.
module integrity_rx #(parameter integer DATA_WIDTH=64)(
 input wire clk,rst_n,
 input wire [DATA_WIDTH-1:0] s_data,
 input wire [15:0] s_crc,
 input wire s_valid,
 output wire s_ready,
 output wire [DATA_WIDTH-1:0] m_data,
 output wire m_valid,
 input wire m_ready,
 output reg crc_error,
 output reg [31:0] error_count
);
 wire [15:0] computed_crc;
 wire crc_ok, ingress_ready, accept;
 crc16_guard #(.DATA_WIDTH(DATA_WIDTH)) crc_checker_inst (
  .data(s_data),.received_crc(s_crc),.computed_crc(computed_crc),.crc_ok(crc_ok));
 assign s_ready=ingress_ready;
 assign accept=s_valid && s_ready;
 elastic_buffer #(.WIDTH(DATA_WIDTH)) output_buffer (
  .clk(clk),.rst_n(rst_n),.s_data(s_data),
  .s_valid(accept && crc_ok),.s_ready(ingress_ready),
  .m_data(m_data),.m_valid(m_valid),.m_ready(m_ready));
 always @(posedge clk or negedge rst_n) begin
  if(!rst_n) begin crc_error<=0; error_count<=0; end
  else begin
   crc_error<=accept && !crc_ok;
   if(accept && !crc_ok && error_count!=32'hFFFFFFFF)
    error_count<=error_count+1'b1;
  end
 end
endmodule
