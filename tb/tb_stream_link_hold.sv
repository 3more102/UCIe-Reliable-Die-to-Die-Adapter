// Directed regression: link-down must retain a pending ingress word.
// Generic ready/valid prototype, not UCIe protocol compliance.
module tb_stream_link_hold;
  reg clk=0;
  always #5 clk=~clk;
  reg rst_n=0, link_up=0, s_valid=0, m_ready=0, credit_return=0;
  reg [63:0] s_data=0;
  wire s_ready, m_valid;
  wire [63:0] m_data;
  wire [7:0] credits;
  stream_adapter dut(.clk(clk),.rst_n(rst_n),.link_up(link_up),
    .s_data(s_data),.s_valid(s_valid),.s_ready(s_ready),
    .m_data(m_data),.m_valid(m_valid),.m_ready(m_ready),
    .credit_return(credit_return),.credits(credits));
  initial begin
    repeat(2) @(negedge clk);
    rst_n=1;
    credit_return=1;
    @(negedge clk);
    credit_return=0;
    link_up=1; s_valid=1; s_data=64'h1234_5678_9abc_def0;
    @(negedge clk);
    if (!s_ready) $fatal(1,"ingress was not accepted");
    s_valid=0; link_up=0; m_ready=1;
    repeat(3) begin
      @(negedge clk);
      if (m_valid) $fatal(1,"output valid while link down");
      if (s_ready) $fatal(1,"input ready while link down");
    end
    m_ready=0; link_up=1;
    #1;
    if (!m_valid || m_data !== 64'h1234_5678_9abc_def0)
      $fatal(1,"buffered word not retained on recovery");
    m_ready=1;
    @(negedge clk);
    if (m_valid) $fatal(1,"duplicate output after transfer");
    $display("PASS: link hold and recovery");
    $finish;
  end
endmodule
