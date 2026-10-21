`timescale 1ns/1ps
// Directed model for a generic outstanding-data buffer; NOT UCIe compliance.
module tb_generic_replay_store;
 reg clk=0;always #5 clk=~clk;
 reg rst_n=0;
 reg [31:0] capture_data=0;
 reg capture_valid=0,retire_oldest=0,request_replay=0,replay_ready=0;
 wire capture_ready,replay_busy,replay_valid;
 wire [31:0] replay_data;
 wire [2:0] occupancy;
 generic_replay_store #(.DATA_WIDTH(32),.DEPTH(4)) dut(
  .clk(clk),.rst_n(rst_n),.capture_data(capture_data),
  .capture_valid(capture_valid),.capture_ready(capture_ready),
  .retire_oldest(retire_oldest),.request_replay(request_replay),
  .replay_busy(replay_busy),.replay_valid(replay_valid),
  .replay_ready(replay_ready),.replay_data(replay_data),.occupancy(occupancy)
 );
 task push_word(input [31:0] w);
  begin
   @(negedge clk);capture_data=w;capture_valid=1;
   #1;if(!capture_ready) $fatal(1,"capture not ready");
   @(negedge clk);capture_valid=0;
  end
 endtask
 task retire_word;
  begin
   @(negedge clk);retire_oldest=1;
   @(negedge clk);retire_oldest=0;
  end
 endtask
 initial begin
  repeat(3) @(negedge clk);rst_n=1;
  push_word(32'h11);push_word(32'h22);
  if(occupancy!==2) $fatal(1,"initial occupancy mismatch");
  @(negedge clk);request_replay=1;
  @(negedge clk);request_replay=0;
  #1;if(!replay_valid || replay_data!==32'h11) $fatal(1,"first replay mismatch");
  repeat(2) begin
   @(negedge clk);
   #1;if(replay_data!==32'h11 || !replay_valid)
     $fatal(1,"stalled replay changed");
  end
  replay_ready=1;
  @(negedge clk);#1;if(replay_data!==32'h22) $fatal(1,"second replay mismatch");
  @(negedge clk);replay_ready=0;
  #1;if(replay_busy!==0 || occupancy!==2) $fatal(1,"replay retired data");
  retire_word();retire_word();
  #1;if(occupancy!==0) $fatal(1,"not drained");
  // Wrap around a nonempty full buffer and preserve order.
  push_word(32'h33);push_word(32'h44);push_word(32'h55);push_word(32'h66);
  if(occupancy!==4 || capture_ready!==0) $fatal(1,"full invariant");
  retire_word();push_word(32'h77);
  @(negedge clk);request_replay=1;
  @(negedge clk);request_replay=0;
  #1;if(!replay_valid || replay_data!==32'h44) $fatal(1,"wrapped replay mismatch");
  replay_ready=1;
  @(negedge clk);#1;if(replay_data!==32'h55) $fatal(1,"expected 55");
  @(negedge clk);#1;if(replay_data!==32'h66) $fatal(1,"expected 66");
  @(negedge clk);#1;if(replay_data!==32'h77) $fatal(1,"expected 77");
  @(negedge clk);replay_ready=0;
  #1;if(replay_busy!==0 || occupancy!==4) $fatal(1,"post-replay count");
  $display("PASS generic replay store: depth=4, wrap, stall, no implicit retire");
  $finish;
 end
 initial begin #3000;$fatal(1,"timeout");end
endmodule
