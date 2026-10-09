// Directed throughput, simultaneous dequeue/enqueue, and stall stability regression.
// Generic elastic-buffer infrastructure; this is not a UCIe compliance test.
module tb_elastic_buffer_stream;
  reg clk = 0;
  always #5 clk = ~clk;
  reg rst_n = 0;
  reg [7:0] s_data = 0;
  reg s_valid = 0;
  wire s_ready;
  wire [7:0] m_data;
  wire m_valid;
  reg m_ready = 0;
  integer i;
  elastic_buffer #(.WIDTH(8)) dut (
    .clk(clk), .rst_n(rst_n), .s_data(s_data), .s_valid(s_valid),
    .s_ready(s_ready), .m_data(m_data), .m_valid(m_valid), .m_ready(m_ready)
  );
  initial begin
    repeat (2) @(negedge clk);
    rst_n = 1;
    s_valid = 1;
    s_data = 8'h10;
    m_ready = 1;
    @(negedge clk);
    if (!m_valid || m_data !== 8'h10)
      $fatal(1, "first word missing");
    // Full-rate operation: output previous word while accepting next word.
    for (i = 1; i < 32; i = i + 1) begin
      s_data = 8'h10 + i;
      if (!s_ready || !m_valid || m_data !== (8'h10 + i - 1))
        $fatal(1, "stream mismatch before edge %0d", i);
      @(negedge clk);
      if (!m_valid || m_data !== (8'h10 + i))
        $fatal(1, "stream mismatch after edge %0d", i);
    end
    // Freeze output under backpressure and verify ready is low.
    m_ready = 0;
    s_data = 8'hFE;
    repeat (4) begin
      @(negedge clk);
      if (s_ready || !m_valid || m_data !== 8'h2F)
        $fatal(1, "stalled output changed");
    end
    s_valid = 0;
    m_ready = 1;
    @(negedge clk);
    if (m_valid) $fatal(1, "buffer failed to drain");
    $display("PASS elastic_buffer_stream");
    $finish;
  end
  initial begin
    #2000;
    $fatal(1, "timeout");
  end
endmodule
