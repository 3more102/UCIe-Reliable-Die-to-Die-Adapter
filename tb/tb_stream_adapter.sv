// End-to-end scoreboard for the project-local single-clock streaming demonstrator.
// This is NOT a UCIe protocol compliance test.
module tb_stream_adapter;
    reg clk = 0;
    always #5 clk = ~clk;
    reg rst_n = 0, link_up = 0;
    reg [7:0] s_data = 0;
    reg s_valid = 0, m_ready = 0, credit_return = 0;
    wire s_ready, m_valid;
    wire [7:0] m_data;
    wire [2:0] credits;
    reg [7:0] expected [0:1023];
    integer head = 0, tail = 0, cycle;
    reg [31:0] rng = 32'hB16B00B5;
    reg [31:0] next_rng;
    reg source_accepted = 1;
    stream_adapter #(.WIDTH(8), .CREDIT_WIDTH(3)) dut (
        .clk(clk), .rst_n(rst_n), .link_up(link_up),
        .s_data(s_data), .s_valid(s_valid), .s_ready(s_ready),
        .m_data(m_data), .m_valid(m_valid), .m_ready(m_ready),
        .credit_return(credit_return), .credits(credits)
    );
    // Sample accepted transfers at the active clock edge, before NBA updates.
    always @(posedge clk) begin
        if (rst_n) begin
            source_accepted = s_valid && s_ready;
            if (m_valid && m_ready) begin
                if (head == tail) $fatal(1, "unexpected output");
                if (m_data !== expected[head])
                    $fatal(1, "data/order mismatch at %0d", head);
                head = head + 1;
            end
            if (s_valid && s_ready) begin
                if (tail >= 1024) $fatal(1, "scoreboard capacity exceeded");
                expected[tail] = s_data;
                tail = tail + 1;
            end
        end
    end
    initial begin
        repeat (3) @(negedge clk);
        rst_n = 1;
        link_up = 1;
        // Preload credits while output is stalled.
        credit_return = 1;
        m_ready = 0;
        repeat (7) @(negedge clk);
        if (credits !== 7) $fatal(1, "credit preload failed");
        for (cycle = 0; cycle < 400; cycle = cycle + 1) begin
            next_rng = rng ^ (rng << 13);
            next_rng = next_rng ^ (next_rng >> 17);
            next_rng = next_rng ^ (next_rng << 5);
            rng = next_rng;
            // Respect ready/valid: hold payload and valid until accepted.
            if (!s_valid || source_accepted) begin
                s_valid = rng[0];
                s_data = cycle[7:0];
            end
            m_ready = rng[1];
            credit_return = rng[2];
            @(negedge clk);
        end
        s_valid = 0;
        m_ready = 1;
        credit_return = 1;
        repeat (20) @(negedge clk);
        if (head != tail) $fatal(1, "undelivered buffered data: %0d", tail-head);
        if (tail == 0) $fatal(1, "no transfers exercised");
        $display("PASS stream_adapter: %0d ordered transfers", tail);
        $finish;
    end
    initial begin #10000; $fatal(1, "timeout"); end
endmodule
