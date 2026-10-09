// Directed credit-accounting regression for the generic (non-UCIe) credit gate.
// Test edge cases: simultaneous return/send, saturation and reset during stall.
module tb_credit_tx_edges;
    reg clk = 0;
    always #5 clk = ~clk;
    reg rst_n = 0, s_valid = 1, m_ready = 1, credit_return = 0;
    reg [7:0] s_data = 8'hA7;
    wire s_ready, m_valid;
    wire [7:0] m_data;
    wire [1:0] credits;
    credit_tx #(.WIDTH(8), .CREDIT_WIDTH(2)) dut (
        .clk(clk), .rst_n(rst_n), .s_data(s_data), .s_valid(s_valid),
        .s_ready(s_ready), .m_data(m_data), .m_valid(m_valid),
        .m_ready(m_ready), .credit_return(credit_return), .credits(credits)
    );
    task tick;
        begin
            @(posedge clk);
            #1;
        end
    endtask
    initial begin
        tick();
        if (credits !== 0 || m_valid !== 0) $fatal(1, "reset");
        @(negedge clk); rst_n = 1; m_ready = 0; credit_return = 1;
        repeat (3) tick();
        if (credits !== 3 || s_ready !== 0) $fatal(1, "saturation");
        tick();
        if (credits !== 3) $fatal(1, "overflow");
        @(negedge clk); m_ready = 1;
        repeat (4) begin
            if (!m_valid || !s_ready || m_data !== 8'hA7)
                $fatal(1, "handshake while credit available");
            tick();
            if (credits !== 3) $fatal(1, "simultaneous return/send");
            @(negedge clk);
        end
        credit_return = 0;
        repeat (3) tick();
        if (credits !== 0 || m_valid !== 0 || s_ready !== 0)
            $fatal(1, "credit drain");
        @(negedge clk); m_ready = 0; credit_return = 1;
        tick();
        if (credits !== 1) $fatal(1, "credit refill");
        @(negedge clk); credit_return = 0; rst_n = 0;
        tick();
        if (credits !== 0 || m_valid !== 0) $fatal(1, "reset during stall");
        $display("PASS credit_tx_edges");
        $finish;
    end
    initial begin #2000; $fatal(1, "timeout"); end
endmodule
