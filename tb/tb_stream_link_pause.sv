// Regression: link-down must not silently consume a buffered transfer.
// This checks the project-local stream demonstrator, not UCIe link recovery.
module tb_stream_link_pause;
    reg clk = 0;
    always #5 clk = ~clk;
    reg rst_n = 0, link_up = 0;
    reg [7:0] s_data = 8'hD3;
    reg s_valid = 0, m_ready = 1, credit_return = 0;
    wire s_ready, m_valid;
    wire [7:0] m_data;
    wire [2:0] credits;
    stream_adapter #(.WIDTH(8), .CREDIT_WIDTH(3)) dut (
        .clk(clk), .rst_n(rst_n), .link_up(link_up),
        .s_data(s_data), .s_valid(s_valid), .s_ready(s_ready),
        .m_data(m_data), .m_valid(m_valid), .m_ready(m_ready),
        .credit_return(credit_return), .credits(credits)
    );
    initial begin
        repeat (2) @(negedge clk);
        rst_n = 1;
        credit_return = 1;
        repeat (2) @(negedge clk);
        credit_return = 0;
        if (credits !== 2) $fatal(1, "credit setup");
        link_up = 1;
        s_valid = 1;
        m_ready = 0;
        @(negedge clk);
        if (!dut.buffered_valid || dut.buffered_data !== 8'hD3)
            $fatal(1, "buffer not populated");
        s_valid = 0;
        link_up = 0;
        m_ready = 1;
        repeat (4) begin
            @(negedge clk);
            if (m_valid || s_ready || !dut.buffered_valid ||
                dut.buffered_data !== 8'hD3 || credits !== 2)
                $fatal(1, "buffered data lost during link pause");
        end
        link_up = 1;
        if (!m_valid || m_data !== 8'hD3)
            $fatal(1, "buffered data not restored");
        @(negedge clk);
        if (m_valid || credits !== 1)
            $fatal(1, "buffered data not transmitted exactly once");
        $display("PASS stream_link_pause");
        $finish;
    end
    initial begin #1000; $fatal(1, "timeout"); end
endmodule
