// Digital profile selection and reliability regression for stream_adapter.
// This does not model line-rate clocks or prove physical GT/s operation.
module tb_stream_rate_profile #(
    parameter integer RATE_PROFILE_GT_S=64
);
  reg clk=0;
  always #5 clk=~clk;
  reg rst_n=0, link_up=0, s_valid=0, m_ready=0, credit_return=0;
  reg [7:0] s_data=0;
  wire s_ready,m_valid,rate_profile_supported;
  wire [7:0] m_data,credits;
  wire [6:0] configured_rate_gt_s;

  stream_adapter #(.WIDTH(8),.CREDIT_WIDTH(8),
                   .RATE_PROFILE_GT_S(RATE_PROFILE_GT_S)) dut (
      .clk(clk),.rst_n(rst_n),.link_up(link_up),
      .s_data(s_data),.s_valid(s_valid),.s_ready(s_ready),
      .m_data(m_data),.m_valid(m_valid),.m_ready(m_ready),
      .credit_return(credit_return),.credits(credits),
      .rate_profile_supported(rate_profile_supported),
      .configured_rate_gt_s(configured_rate_gt_s));

  initial begin
    repeat (2) @(negedge clk);
    rst_n=1;
    #1;

    if (RATE_PROFILE_GT_S == 48 || RATE_PROFILE_GT_S == 64) begin
      if (!rate_profile_supported || configured_rate_gt_s !== RATE_PROFILE_GT_S)
        $fatal(1,"valid profile %0d GT/s was not propagated",RATE_PROFILE_GT_S);

      // Grant one credit, accept a word, and prove it is held across output
      // backpressure and link-down, then delivered once after recovery.
      link_up=1;
      credit_return=1;
      @(negedge clk);
      credit_return=0;
      if (credits !== 1) $fatal(1,"initial credit grant failed");
      s_data=8'hA5; s_valid=1;
      #1;
      if (!s_ready) $fatal(1,"profile %0d GT/s did not accept ingress",RATE_PROFILE_GT_S);
      @(posedge clk);
      @(negedge clk);
      s_valid=0; m_ready=0;
      #1;
      if (!m_valid || m_data !== 8'hA5)
        $fatal(1,"profile %0d GT/s lost buffered data under stall",RATE_PROFILE_GT_S);
      repeat (2) begin
        @(negedge clk);
        if (!m_valid || m_data !== 8'hA5)
          $fatal(1,"profile %0d GT/s changed stalled data",RATE_PROFILE_GT_S);
      end

      link_up=0; m_ready=1;
      #1;
      if (m_valid || s_ready) $fatal(1,"traffic visible while link is down");
      repeat (2) begin
        @(negedge clk);
        if (m_valid || s_ready || !dut.buffered_valid || dut.buffered_data !== 8'hA5)
          $fatal(1,"profile %0d GT/s failed to retain data during link-down",RATE_PROFILE_GT_S);
      end

      link_up=1; m_ready=0;
      #1;
      if (!m_valid || m_data !== 8'hA5)
        $fatal(1,"profile %0d GT/s did not restore pending data",RATE_PROFILE_GT_S);
      m_ready=1;
      @(posedge clk);
      @(negedge clk);
      if (m_valid || dut.buffered_valid || credits !== 0)
        $fatal(1,"profile %0d GT/s transfer was duplicated or credit not consumed",RATE_PROFILE_GT_S);

      // Credit-return events while the link is down are ignored. This keeps
      // inactive-link events from creating stale credit for later traffic.
      link_up=0; credit_return=1;
      repeat (2) begin
        @(negedge clk);
        if (credits !== 0)
          $fatal(1,"profile %0d GT/s counted credit while link was down",RATE_PROFILE_GT_S);
      end
      credit_return=0; link_up=1;

      // With no credits, a second word must remain buffered until credit returns.
      s_data=8'h3C; s_valid=1;
      #1;
      if (!s_ready) $fatal(1,"empty ingress buffer did not accept second word");
      @(posedge clk);
      @(negedge clk);
      s_valid=0; m_ready=0;
      #1;
      if (m_valid || !dut.buffered_valid || dut.buffered_data !== 8'h3C)
        $fatal(1,"profile %0d GT/s failed to hold data without credit",RATE_PROFILE_GT_S);
      credit_return=1;
      @(posedge clk);
      @(negedge clk);
      credit_return=0;
      #1;
      if (!m_valid || m_data !== 8'h3C)
        $fatal(1,"profile %0d GT/s did not resume after credit return",RATE_PROFILE_GT_S);
      m_ready=1;
      @(posedge clk);
      @(negedge clk);
      if (m_valid || dut.buffered_valid || credits !== 0)
        $fatal(1,"profile %0d GT/s credit recovery did not complete cleanly",RATE_PROFILE_GT_S);

      $display("PASS stream profile=%0d GT/s (digital datapath only)",RATE_PROFILE_GT_S);
    end else begin
      if (rate_profile_supported || configured_rate_gt_s !== 0)
        $fatal(1,"unsupported profile %0d GT/s was accepted",RATE_PROFILE_GT_S);
      link_up=1; credit_return=1; s_valid=1; s_data=8'h5A; m_ready=1;
      #1;
      if (s_ready || m_valid)
        $fatal(1,"unsupported profile %0d GT/s enabled datapath",RATE_PROFILE_GT_S);
      @(posedge clk);
      @(negedge clk);
      if (dut.buffered_valid || m_valid || credits !== 0)
        $fatal(1,"unsupported profile %0d GT/s captured traffic",RATE_PROFILE_GT_S);
      $display("PASS unsupported profile=%0d GT/s rejected",RATE_PROFILE_GT_S);
    end
    $finish;
  end

  initial begin
    #2000;
    $fatal(1,"timeout in profile %0d GT/s test",RATE_PROFILE_GT_S);
  end
endmodule
