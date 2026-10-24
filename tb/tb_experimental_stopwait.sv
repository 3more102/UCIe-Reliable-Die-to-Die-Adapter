// Independent directed end-to-end generic link regression. NOT UCIe compliance.
`timescale 1ns/1ps
module tb_experimental_stopwait;
 localparam integer DW=32,N=24;
 reg clk=0;always #5 clk=~clk;
 reg rst_n=0,s_valid=0,m_ready=0;
 reg [DW-1:0] s_data=0;
 wire s_ready,m_valid;
 wire [DW-1:0] m_data;
 wire [DW+16:0] tx_frame,rx_frame;
 wire tx_valid,tx_ready,rx_valid,rx_ready;
 wire ack_valid,ack_seq,ack_ok,pending;
 wire [31:0] retry_count,crc_error_count,fault_count;
 integer sent=0,received=0,cycle=0,i;
 reg [DW-1:0] expected[0:N-1];
 reg held_valid=0;
 reg [DW-1:0] held_data=0;
 experimental_stopwait_tx #(.DATA_WIDTH(DW)) tx(
  .clk(clk),.rst_n(rst_n),.s_data(s_data),.s_valid(s_valid),
  .s_ready(s_ready),.frame_data(tx_frame),.frame_valid(tx_valid),
  .frame_ready(tx_ready),.ack_valid(ack_valid),.ack_seq(ack_seq),
  .ack_ok(ack_ok),.retry_count(retry_count),.pending(pending)
 );
 experimental_fault_link #(.FRAME_WIDTH(DW+17),.CORRUPT_BIT(0)) fault_link(
  .clk(clk),.rst_n(rst_n),.enable_single_fault(1'b1),
  .s_data(tx_frame),.s_valid(tx_valid),.s_ready(tx_ready),
  .m_data(rx_frame),.m_valid(rx_valid),.m_ready(rx_ready),
  .fault_count(fault_count)
 );
 experimental_stopwait_rx #(.DATA_WIDTH(DW)) rx(
  .clk(clk),.rst_n(rst_n),.frame_data(rx_frame),.frame_valid(rx_valid),
  .frame_ready(rx_ready),.m_data(m_data),.m_valid(m_valid),
  .m_ready(m_ready),.ack_valid(ack_valid),.ack_seq(ack_seq),
  .ack_ok(ack_ok),.crc_error_count(crc_error_count)
 );
 // Capture genuine Icarus simulation waveform for Meeting 2 evidence.
 // The trace describes a generic teaching link, NOT UCIe FDI/replay behavior.
 initial begin
  $dumpfile("build/experimental_stopwait.vcd");
  $dumpvars(0, clk,rst_n,s_valid,s_ready,tx_valid,tx_ready,rx_valid,rx_ready,
            ack_valid,ack_seq,ack_ok,m_valid,m_ready,pending,
            fault_count,crc_error_count,retry_count,sent,received);
 end
 // CSV-style per-clock samples embedded in the runner log for reproducible
 // rendering without inventing an idealized timing waveform.
 always @(posedge clk) if(rst_n)
  $display("TRACECSV,%0d,%0d,%0d,%0d,%0d,%0d,%0d,%0d,%0d,%0d,%0d,%0d,%0d,%0d,%0d",
    cycle,s_valid,s_ready,tx_valid,rx_valid,rx_ready,
    ack_valid,ack_ok,m_valid,m_ready,
    fault_count,crc_error_count,retry_count,sent,received);
 // Golden queue originates only at accepted source interface.
 always @(posedge clk) if(rst_n) begin
  if(m_valid && m_ready) begin
   if(received>=sent) $fatal(1,"unexpected/duplicate output cycle=%0d",cycle);
   if(m_data !== expected[received]) $fatal(1,"data/order mismatch idx=%0d",received);
   received=received+1;
  end
  if(s_valid && s_ready) begin
   if(sent==N) $fatal(1,"unexpected input");
   expected[sent]=s_data;sent=sent+1;
  end
  if(held_valid && (!m_valid || m_data !== held_data))
   $fatal(1,"unstable sink data under backpressure");
  held_valid=m_valid && !m_ready;
  held_data=m_data;
  cycle=cycle+1;
 end
 // Repeated sink stalls; the test must terminate despite backpressure.
 always @(negedge clk) if(rst_n) m_ready=((cycle%7)>2);
 task send_word;
  input [DW-1:0] w;
  begin
   @(negedge clk);
   while(!s_ready) @(negedge clk);
   s_data=w;s_valid=1;
   @(negedge clk);s_valid=0;
  end
 endtask
 initial begin
  repeat(3) @(negedge clk);
  rst_n=1;
  for(i=0;i<N;i=i+1) send_word(32'hACE00000+i*37);
  wait(received==N);
  repeat(4) @(negedge clk);
  if(sent!==N || received!==N || pending!==0)
   $fatal(1,"undrained traffic sent=%0d received=%0d",sent,received);
  if(fault_count!==1 || crc_error_count!==1 || retry_count!==1)
   $fatal(1,"fault proof failed injected=%0d detected=%0d retries=%0d",
          fault_count,crc_error_count,retry_count);
  $display("PASS non-UCIe link: sent=%0d received=%0d faults=%0d crc=%0d retries=%0d cycles=%0d",
           sent,received,fault_count,crc_error_count,retry_count,cycle);
  $finish;
 end
 initial begin #100000;
  $fatal(1,"TIMEOUT sent=%0d received=%0d",sent,received);
 end
endmodule
