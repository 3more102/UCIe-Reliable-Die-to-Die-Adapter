// End-to-end experimental integrity loopback, not a UCIe link.
module tb_integrity_loopback;
 reg clk=0;
 always #5 clk=~clk;
 reg rst_n=0,tx_valid=0,rx_ready=0,inject=0;
 reg [71:0] tx_data=0;
 wire tx_ready,wire_valid,wire_ready,rx_valid,crc_error;
 wire [71:0] wire_data,rx_data;
 wire [15:0] wire_crc;
 wire [31:0] error_count;
 integrity_tx #(.DATA_WIDTH(72)) tx(
  .s_data(tx_data),.s_valid(tx_valid),.s_ready(tx_ready),
  .m_data(wire_data),.m_crc(wire_crc),.m_valid(wire_valid),.m_ready(wire_ready));
 integrity_rx #(.DATA_WIDTH(72)) rx(
  .clk(clk),.rst_n(rst_n),.s_data(wire_data),
  .s_crc(wire_crc ^ {15'b0,inject}),.s_valid(wire_valid),
  .s_ready(wire_ready),.m_data(rx_data),.m_valid(rx_valid),
  .m_ready(rx_ready),.crc_error(crc_error),.error_count(error_count));
 initial begin
  repeat(2) @(negedge clk);
  rst_n=1; tx_data=72'h313233343536373839; tx_valid=1;
  @(negedge clk);
  if(!rx_valid || rx_data!==tx_data)
   $fatal(1,"loopback valid data mismatch");
  tx_valid=0; rx_ready=1;
  @(negedge clk);
  if(rx_valid) $fatal(1,"loopback output not consumed");
  rx_ready=0; tx_valid=1; inject=1;
  @(negedge clk);
  if(rx_valid || !crc_error || error_count!==1)
   $fatal(1,"corrupt loopback data not rejected");
  tx_valid=0; inject=0;
  @(negedge clk);
  if(crc_error || error_count!==1)
   $fatal(1,"loopback error accounting incorrect");
  $display("PASS experimental integrity loopback"); $finish;
 end
 initial begin #1000; $fatal(1,"timeout"); end
endmodule
