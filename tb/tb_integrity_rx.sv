module tb_integrity_rx;
 reg clk=0;
 always #5 clk=~clk;
 reg rst_n=0,s_valid=0,m_ready=0;
 reg [71:0] s_data=0;
 reg [15:0] s_crc=0;
 wire s_ready,m_valid,crc_error;
 wire [71:0] m_data;
 wire [31:0] error_count;
 integrity_rx #(.DATA_WIDTH(72)) dut(
  .clk(clk),.rst_n(rst_n),.s_data(s_data),.s_crc(s_crc),
  .s_valid(s_valid),.s_ready(s_ready),.m_data(m_data),
  .m_valid(m_valid),.m_ready(m_ready),
  .crc_error(crc_error),.error_count(error_count));
 initial begin
  repeat(2) @(negedge clk);
  rst_n=1;
  s_data=72'h313233343536373839;
  s_crc=16'h29B1;
  s_valid=1;
  @(negedge clk);
  if(!m_valid || m_data!==72'h313233343536373839)
   $fatal(1,"valid word not buffered");
  s_valid=0; m_ready=1;
  @(negedge clk);
  if(m_valid) $fatal(1,"valid word not consumed");
  m_ready=0; s_valid=1; s_crc=16'h29B0;
  @(negedge clk);
  if(m_valid || !crc_error || error_count!==1)
   $fatal(1,"bad CRC not dropped/counted");
  s_valid=0;
  @(negedge clk);
  if(crc_error || error_count!==1)
   $fatal(1,"error pulse/count invalid");
  $display("PASS integrity_rx"); $finish;
 end
 initial begin #1000; $fatal(1,"timeout"); end
endmodule
