module tb_stream_adapter;
    reg clk=0;
    always #5 clk=~clk;
    reg rst_n=0, link_up=0, s_valid=0, m_ready=0, credit_return=0;
    reg [7:0] s_data=0;
    wire s_ready,m_valid;
    wire [7:0] m_data,credits;
    stream_adapter #(.WIDTH(8),.CREDIT_WIDTH(8)) dut (
        .clk(clk),.rst_n(rst_n),.link_up(link_up),
        .s_data(s_data),.s_valid(s_valid),.s_ready(s_ready),
        .m_data(m_data),.m_valid(m_valid),.m_ready(m_ready),
        .credit_return(credit_return),.credits(credits));
    initial begin
        repeat(2) @(negedge clk);
        rst_n=1;
        link_up=1;
        s_valid=1;
        s_data=8'hC3;
        @(negedge clk);
        if (!dut.buffered_valid || dut.buffered_data !== 8'hC3)
            $fatal(1,"buffer did not capture data");
        s_valid=0;
        link_up=0;
        credit_return=1;
        m_ready=1;
        @(negedge clk);
        credit_return=0;
        repeat(3) begin
            if (m_valid || s_ready || !dut.buffered_valid ||
                dut.buffered_data !== 8'hC3)
                $fatal(1,"buffer lost data during link down");
            @(negedge clk);
        end
        link_up=1;
        if (!m_valid || m_data !== 8'hC3)
            $fatal(1,"buffered data not available after recovery");
        @(negedge clk);
        if (m_valid || dut.buffered_valid)
            $fatal(1,"buffer did not drain after recovery");
        $display("PASS stream_adapter link-down preservation");
        $finish;
    end
    initial begin #1000; $fatal(1,"timeout"); end
endmodule
