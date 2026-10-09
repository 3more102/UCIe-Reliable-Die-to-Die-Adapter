module tb_elastic_buffer;
    reg clk = 0;
    always #5 clk = ~clk;
    reg rst_n = 0;
    reg [7:0] s_data = 0;
    reg s_valid = 0;
    wire s_ready;
    wire [7:0] m_data;
    wire m_valid;
    reg m_ready = 0;

    elastic_buffer #(.WIDTH(8)) dut (
        .clk(clk), .rst_n(rst_n),
        .s_data(s_data), .s_valid(s_valid), .s_ready(s_ready),
        .m_data(m_data), .m_valid(m_valid), .m_ready(m_ready)
    );

    initial begin
        repeat (2) @(negedge clk);
        rst_n = 1;
        s_data = 8'hA5;
        s_valid = 1;
        @(negedge clk);
        if (!m_valid || m_data !== 8'hA5) $fatal(1, "enqueue failed");
        s_valid = 0;
        if (s_ready !== 0) $fatal(1, "backpressure failed");
        repeat (3) begin
            @(negedge clk);
            if (!m_valid || m_data !== 8'hA5) $fatal(1, "data not held");
        end
        m_ready = 1;
        @(negedge clk);
        if (m_valid) $fatal(1, "dequeue failed");
        $display("PASS elastic_buffer");
        $finish;
    end
    initial begin
        #1000;
        $fatal(1, "timeout");
    end
endmodule
