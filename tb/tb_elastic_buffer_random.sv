// Deterministic ready/valid reference-queue regression.
// Exercises simultaneous push/pop, full backpressure, and reset flushing.
module tb_elastic_buffer_random;
  reg clk = 0;
  always #5 clk = ~clk;
  reg rst_n = 0;
  reg [15:0] s_data = 0;
  reg s_valid = 0;
  reg m_ready = 0;
  wire s_ready, m_valid;
  wire [15:0] m_data;
  elastic_buffer #(.WIDTH(16)) dut (
    .clk(clk), .rst_n(rst_n), .s_data(s_data), .s_valid(s_valid),
    .s_ready(s_ready), .m_data(m_data), .m_valid(m_valid), .m_ready(m_ready)
  );
  integer cycle, seed = 32'h1234567, count = 0, head = 0, tail = 0;
  reg [15:0] expected [0:4095];
  reg push, pop;
  initial begin
    for (cycle = 0; cycle < 2000; cycle = cycle + 1) begin
      @(negedge clk);
      rst_n = (cycle > 2) && (cycle != 500) && (cycle != 1000);
      s_valid = ($random(seed) & 3) != 0;
      m_ready = ($random(seed) & 3) != 0;
      s_data = $random(seed);
      #1;
      if (!rst_n) begin
        if (m_valid !== 1'b0) $fatal(1, "reset did not clear valid");
        head = 0; tail = 0; count = 0;
      end else begin
        if (m_valid !== (count != 0)) $fatal(1, "valid mismatch at %0d", cycle);
        if (s_ready !== ((count == 0) || m_ready))
          $fatal(1, "ready mismatch at %0d", cycle);
        if (count != 0 && m_data !== expected[head])
          $fatal(1, "payload mismatch at %0d", cycle);
      end
      push = rst_n && s_valid && s_ready;
      pop = rst_n && m_valid && m_ready;
      @(posedge clk);
      if (pop) begin head = head + 1; count = count - 1; end
      if (push) begin expected[tail] = s_data; tail = tail + 1; count = count + 1; end
      if (count < 0 || count > 1) $fatal(1, "occupancy invalid");
    end
    $display("PASS elastic_buffer randomized 2000 cycles");
    $finish;
  end
endmodule
