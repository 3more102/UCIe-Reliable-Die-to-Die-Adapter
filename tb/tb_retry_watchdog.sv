module tb_retry_watchdog;
 reg clk=0;
 always #5 clk=~clk;
 reg rst_n=0,outstanding=0,progress=0;
 wire timeout_pulse;
 retry_watchdog #(.COUNTER_WIDTH(4),.TIMEOUT_CYCLES(3)) dut(
  .clk(clk),.rst_n(rst_n),.outstanding(outstanding),
  .progress(progress),.timeout_pulse(timeout_pulse));
 initial begin
  repeat(2) @(negedge clk);
  rst_n=1; outstanding=1;
  repeat(2) @(negedge clk);
  if(timeout_pulse) $fatal(1,"premature timeout");
  @(negedge clk);
  if(!timeout_pulse) $fatal(1,"missing timeout");
  @(negedge clk);
  if(timeout_pulse) $fatal(1,"timeout pulse stuck");
  progress=1;
  @(negedge clk);
  if(timeout_pulse) $fatal(1,"progress did not reset timeout");
  progress=0; outstanding=0;
  repeat(4) @(negedge clk);
  if(timeout_pulse) $fatal(1,"timeout while idle");
  $display("PASS retry watchdog"); $finish;
 end
 initial begin #1000; $fatal(1,"timeout"); end
endmodule
