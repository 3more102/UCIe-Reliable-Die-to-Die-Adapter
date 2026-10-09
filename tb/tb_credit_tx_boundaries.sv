// Directed boundary regression for generic credit transmitter.
// This is NOT a normative UCIe protocol test.
module tb_credit_tx_boundaries;
  reg clk = 0;
  always #5 clk = ~clk;
  reg rst_n = 0;
  reg [7:0] s_data = 8'hA5;
  reg s_valid = 1;
  reg m_ready = 0;
  reg credit_return = 0;
  wire s_ready, m_valid;
  wire [7:0] m_data;
  wire [1:0] credits;
  integer i;
  credit_tx #(.WIDTH(8), .CREDIT_WIDTH(2)) dut (
    .clk(clk), .rst_n(rst_n), .s_data(s_data), .s_valid(s_valid),
    .s_ready(s_ready), .m_data(m_data), .m_valid(m_valid),
    .m_ready(m_ready), .credit_return(credit_return), .credits(credits)
  );
  task tick;
    begin
      @(posedge clk);
      #1;
    end
  endtask
  initial begin
    tick();
    if (credits !== 0 || m_valid !== 0 || s_ready !== 0)
      $fatal(1, "reset invariant");
    @(negedge clk);
    rst_n = 1;
    credit_return = 1;
    for (i = 0; i < 8; i = i + 1) tick();
    if (credits !== 3) $fatal(1, "credit overflow");
    @(negedge clk);
    m_ready = 1;
    tick();
    if (credits !== 3) $fatal(1, "simultaneous send and return at full");
    @(negedge clk);
    credit_return = 0;
    for (i = 0; i < 3; i = i + 1) tick();
    if (credits !== 0 || m_valid !== 0 || s_ready !== 0)
      $fatal(1, "credit underflow");
    @(negedge clk);
    credit_return = 1;
    tick();
    if (credits !== 1) $fatal(1, "return after empty");
    @(negedge clk);
    credit_return = 0;
    m_ready = 0;
    repeat (3) tick();
    if (credits !== 1 || m_valid !== 1 || s_ready !== 0 || m_data !== 8'hA5)
      $fatal(1, "backpressure retention");
    $display("PASS credit_tx boundaries");
    $finish;
  end
  initial begin #2000; $fatal(1, "timeout"); end
endmodule
