// Deterministic ready/valid stress test for generic elastic buffer.
// This is NOT a UCIe compliance test.
module tb_elastic_buffer_stress;
  reg clk = 0;
  always #5 clk = ~clk;
  reg rst_n = 0;
  reg [15:0] s_data = 0;
  reg s_valid = 0;
  wire s_ready;
  wire [15:0] m_data;
  wire m_valid;
  reg m_ready = 0;
  integer cycle, sent = 0, received = 0;
  integer seed = 32'h13579bdf;
  reg [15:0] expected [0:1023];
  reg [15:0] held_data;
  reg held = 0;
  reg push, pop;
  elastic_buffer #(.WIDTH(16)) dut (
    .clk(clk), .rst_n(rst_n), .s_data(s_data), .s_valid(s_valid),
    .s_ready(s_ready), .m_data(m_data), .m_valid(m_valid), .m_ready(m_ready)
  );
  initial begin
    repeat (3) @(negedge clk);
    rst_n = 1;
    for (cycle = 0; cycle < 600; cycle = cycle + 1) begin
      // Drive on falling edges, sample handshakes before the rising edge.
      s_valid = (cycle < 500) && (($random(seed) & 3) != 0);
      m_ready = (cycle >= 500) || (($random(seed) & 3) != 0);
      s_data = cycle[15:0] ^ 16'h5a3c;
      #1;
      if (held && (!m_valid || m_data !== held_data))
        $fatal(1, "output changed under stall at cycle %0d", cycle);
      push = s_valid && s_ready;
      pop = m_valid && m_ready;
      if (pop) begin
        if (received >= sent || m_data !== expected[received])
          $fatal(1, "scoreboard mismatch at cycle %0d", cycle);
        received = received + 1;
      end
      if (push) begin
        expected[sent] = s_data;
        sent = sent + 1;
      end
      held = m_valid && !m_ready;
      held_data = m_data;
      @(negedge clk);
    end
    if (received != sent || m_valid)
      $fatal(1, "not drained: sent=%0d received=%0d", sent, received);
    $display("PASS elastic_buffer_stress sent=%0d received=%0d", sent, received);
    $finish;
  end
endmodule
