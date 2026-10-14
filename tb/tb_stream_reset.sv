// Project-defined reset isolation and flush regression for the generic stream model.
module tb_stream_reset #(
    parameter integer RATE_PROFILE_GT_S = 64
);
    reg clk = 0;
    always #5 clk = ~clk;

    reg rst_n = 0;
    reg link_up = 1;
    reg [7:0] s_data = 8'hC3;
    reg s_valid = 1;
    wire s_ready;
    wire [7:0] m_data;
    wire m_valid;
    reg m_ready = 1;
    reg credit_return = 1;
    wire [1:0] credits;
    wire rate_profile_supported;
    wire [6:0] configured_rate_gt_s;

    stream_adapter #(
        .WIDTH(8),
        .CREDIT_WIDTH(2),
        .RATE_PROFILE_GT_S(RATE_PROFILE_GT_S)
    ) dut (
        .clk(clk), .rst_n(rst_n), .link_up(link_up),
        .s_data(s_data), .s_valid(s_valid), .s_ready(s_ready),
        .m_data(m_data), .m_valid(m_valid), .m_ready(m_ready),
        .credit_return(credit_return), .credits(credits),
        .rate_profile_supported(rate_profile_supported),
        .configured_rate_gt_s(configured_rate_gt_s)
    );

    initial begin
        repeat (2) @(posedge clk);
        #1;
        if (!rate_profile_supported || configured_rate_gt_s !== RATE_PROFILE_GT_S)
            $fatal(1, "profile %0d GT/s configuration missing", RATE_PROFILE_GT_S);
        if (s_ready || m_valid || dut.buffered_valid || credits !== 0)
            $fatal(1, "traffic or state visible while reset is asserted");

        // Release reset with the source idle, then create a stalled pending word.
        @(negedge clk);
        rst_n = 1;
        s_valid = 0;
        m_ready = 0;
        credit_return = 1;
        @(posedge clk);
        #1;
        @(negedge clk);
        credit_return = 0;
        if (credits !== 1) $fatal(1, "credit grant after reset failed");

        s_data = 8'hA5;
        s_valid = 1;
        #1;
        if (!s_ready) $fatal(1, "ingress not ready after reset");
        @(posedge clk);
        #1;
        @(negedge clk);
        s_valid = 0;
        #1;
        if (!dut.buffered_valid || !m_valid || m_data !== 8'hA5 || credits !== 1)
            $fatal(1, "pending word setup failed");

        // Asserting reset while link_up remains high must immediately quiesce
        // the interfaces and asynchronously clear the pending word and credit.
        rst_n = 0;
        #1;
        if (s_ready || m_valid || dut.buffered_valid || credits !== 0)
            $fatal(1, "reset did not quiesce and clear pending state");

        // Attempted traffic during reset must not be accepted or retained.
        s_data = 8'h3C;
        s_valid = 1;
        m_ready = 1;
        credit_return = 1;
        #1;
        if (s_ready || m_valid || dut.buffered_valid || credits !== 0)
            $fatal(1, "traffic was accepted while reset was asserted");
        repeat (2) @(posedge clk);
        #1;
        if (dut.buffered_valid || m_valid || credits !== 0)
            $fatal(1, "reset-period traffic was retained");

        // Release reset idle, then check a fresh transaction completes once.
        @(negedge clk);
        s_valid = 0;
        credit_return = 0;
        m_ready = 0;
        rst_n = 1;
        #1;
        if (dut.buffered_valid || m_valid || credits !== 0)
            $fatal(1, "stale state survived reset release");

        credit_return = 1;
        @(posedge clk);
        #1;
        @(negedge clk);
        credit_return = 0;
        if (credits !== 1) $fatal(1, "post-reset credit grant failed");

        s_data = 8'h5A;
        s_valid = 1;
        m_ready = 1;
        #1;
        if (!s_ready) $fatal(1, "fresh post-reset word was not accepted");
        @(posedge clk);
        #1;
        @(negedge clk);
        s_valid = 0;
        #1;
        if (!m_valid || m_data !== 8'h5A)
            $fatal(1, "fresh post-reset word did not reach output");
        @(posedge clk);
        #1;
        if (m_valid || dut.buffered_valid || credits !== 0)
            $fatal(1, "post-reset transaction was duplicated or not consumed");

        $display("PASS stream reset profile=%0d GT/s", RATE_PROFILE_GT_S);
        $finish;
    end

    initial begin
        #2000;
        $fatal(1, "timeout in reset profile %0d GT/s test", RATE_PROFILE_GT_S);
    end
endmodule
