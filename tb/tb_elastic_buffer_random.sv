module tb_elastic_buffer_random;
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
  reg [15:0] expected [0:2047];
  reg [15:0] held_data;
  reg held_valid = 0;

  elastic_buffer #(.WIDTH(16)) dut (
    .clk(clk), .rst_n(rst_n),
    .s_data(s_data), .s_valid(s_valid), .s_ready(s_ready),
    .m_data(m_data), .m_valid(m_valid), .m_ready(m_ready)
  );

  initial begin
    repeat (3) @(negedge clk);
    rst_n = 1;
    for (cycle = 0; cycle < 1000; cycle = cycle + 1) begin
      @(negedge clk);
      s_valid = ($random(seed) & 3) != 0;
      m_ready = ($random(seed) & 3) != 0;
      s_data = $random(seed);
      #1;
      if (held_valid && (!m_valid || m_data !== held_data))
        $fatal(1, "output changed during stall");
      @(posedge clk);
      if (m_valid && m_ready) begin
        if (received >= sent || m_data !== expected[received])
          $fatal(1, "FIFO ordering/data error at cycle %0d", cycle);
        received = received + 1;
      end
      if (s_valid && s_ready) begin
        expected[sent] = s_data;
        sent = sent + 1;
      end
      held_valid = m_valid && !m_ready;
      held_data = m_data;
    end
    @(negedge clk);
    s_valid = 0;
    m_ready = 1;
    repeat (3) begin
      @(posedge clk);
      if (m_valid && m_ready) begin
        if (received >= sent || m_data !== expected[received])
          $fatal(1, "drain ordering/data error");
        received = received + 1;
      end
    end
    if (received != sent) $fatal(1, "undrained data: %0d/%0d", received, sent);
    $display("PASS random elastic buffer: %0d transactions", received);
    $finish;
  end
  initial begin
    #20000;
    $fatal(1, "timeout");
  end
endmodule
