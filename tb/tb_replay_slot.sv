module tb_replay_slot;
 reg clk=0;
 always #5 clk=~clk;
 reg rst_n=0,s_valid=0,m_ready=0,ack=0,retry_req=0;
 reg [7:0] s_data=0;
 wire s_ready,m_valid,outstanding;
 wire [7:0] m_data;
 replay_slot #(.WIDTH(8)) dut(
  .clk(clk),.rst_n(rst_n),.s_data(s_data),.s_valid(s_valid),
  .s_ready(s_ready),.m_data(m_data),.m_valid(m_valid),
  .m_ready(m_ready),.ack(ack),.retry_req(retry_req),
  .outstanding(outstanding));
 initial begin
  repeat(2) @(negedge clk);
  rst_n=1; s_data=8'hA5; s_valid=1;
  @(negedge clk);
  if(!outstanding || s_ready || !m_valid || m_data!==8'hA5)
   $fatal(1,"slot failed to capture word");
  s_valid=0; m_ready=1;
  @(negedge clk);
  if(m_valid || !outstanding)
   $fatal(1,"sent word not held for ACK");
  retry_req=1;
  @(negedge clk);
  if(!m_valid || m_data!==8'hA5)
   $fatal(1,"retry failed to re-arm stored word");
  retry_req=0;
  @(negedge clk);
  if(m_valid || !outstanding)
   $fatal(1,"replayed word not held for ACK");
  ack=1;
  @(negedge clk);
  if(outstanding || !s_ready || m_valid)
   $fatal(1,"ACK did not release slot");
  $display("PASS replay slot stop-and-wait"); $finish;
 end
 initial begin #1000; $fatal(1,"timeout"); end
endmodule
