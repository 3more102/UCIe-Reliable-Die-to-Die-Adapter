module tb_credit_tx;
    reg clk=0;
    always #5 clk=~clk;
    reg rst_n=0;
    reg [7:0] s_data=8'h5A;
    reg s_valid=1;
    wire s_ready, m_valid;
    wire [7:0] m_data;
    reg m_ready=1, credit_return=0;
    wire [2:0] credits;
    credit_tx #(.WIDTH(8),.CREDIT_WIDTH(3)) dut (
        .clk(clk),.rst_n(rst_n),.s_data(s_data),.s_valid(s_valid),
        .s_ready(s_ready),.m_data(m_data),.m_valid(m_valid),
        .m_ready(m_ready),.credit_return(credit_return),.credits(credits));
    initial begin
        repeat(2) @(negedge clk);
        if (credits !== 0 || s_ready || m_valid) $fatal(1,"reset/zero-credit");
        rst_n=1;
        credit_return=1;
        @(negedge clk);
        credit_return=0;
        if (credits !== 1 || !m_valid || !s_ready) $fatal(1,"credit grant");
        m_ready=0;
        repeat(2) @(negedge clk);
        if (credits !== 1 || !m_valid || s_ready) $fatal(1,"stall");
        m_ready=1;
        @(negedge clk);
        if (credits !== 0 || m_valid || s_ready) $fatal(1,"credit consumption");
        $display("PASS credit_tx");
        $finish;
    end
    initial begin #1000; $fatal(1,"timeout"); end
endmodule
