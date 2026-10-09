// Directed throughput and backpressure test for generic elastic buffer.
module tb_elastic_throughput;
    reg clk=0;
    always #5 clk=~clk;
    reg rst_n=0;
    reg [7:0] s_data=0;
    reg s_valid=0;
    wire s_ready;
    wire [7:0] m_data;
    wire m_valid;
    reg m_ready=0;
    integer i;
    elastic_buffer #(.WIDTH(8)) dut (
        .clk(clk),.rst_n(rst_n),.s_data(s_data),.s_valid(s_valid),
        .s_ready(s_ready),.m_data(m_data),.m_valid(m_valid),
        .m_ready(m_ready));
    initial begin
        repeat(2) @(negedge clk);
        rst_n=1;
        s_valid=1;
        m_ready=1;
        for(i=0;i<32;i=i+1) begin
            s_data=i;
            #1;
            if (!s_ready) $fatal(1,"unexpected backpressure");
            @(negedge clk);
            if (!m_valid || m_data !== i[7:0])
                $fatal(1,"throughput mismatch at beat %0d",i);
        end
        s_valid=0;
        @(negedge clk);
        if (m_valid) $fatal(1,"buffer not empty");
        $display("PASS elastic throughput");
        $finish;
    end
    initial begin #2000; $fatal(1,"timeout"); end
endmodule
