// Randomized end-to-end regression for the generic stream adapter.
// The rate parameter is digital profile metadata; this is not line-rate modeling.
module tb_stream_random #(
    parameter integer RATE_PROFILE_GT_S = 64
);
    reg clk = 0;
    always #5 clk = ~clk;

    reg rst_n = 0;
    reg link_up = 0;
    reg [15:0] s_data = 0;
    reg s_valid = 0;
    wire s_ready;
    wire [15:0] m_data;
    wire m_valid;
    reg m_ready = 0;
    reg credit_return = 0;
    wire [1:0] credits;
    wire rate_profile_supported;
    wire [6:0] configured_rate_gt_s;

    stream_adapter #(
        .WIDTH(16),
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

    reg [15:0] expected [0:1023];
    reg [15:0] held_output_data = 0;
    reg held_output_stalled = 0;
    reg [15:0] pending_input_data = 0;
    reg pending_input = 0;
    reg [1:0] model_credits = 0;
    integer sent = 0;
    integer received = 0;
    integer seed = 32'h6493_4801;
    integer cycle;
    integer drain_cycle;

    task automatic sample_cycle;
        reg send_now;
        reg accept_now;
        begin
            @(posedge clk);
            send_now = m_valid && m_ready;
            accept_now = s_valid && s_ready;

            if (send_now) begin
                if (model_credits == 0)
                    $fatal(1, "output handshake without modeled credit");
                if (received >= sent || m_data !== expected[received])
                    $fatal(1, "output ordering/data error at cycle %0d", cycle);
                received = received + 1;
            end

            if (accept_now) begin
                if (sent >= 1024) $fatal(1, "scoreboard capacity exceeded");
                expected[sent] = s_data;
                sent = sent + 1;
                pending_input = 0;
            end

            case ({credit_return, send_now})
                2'b10: if (model_credits != 2'b11) model_credits = model_credits + 1'b1;
                2'b01: model_credits = model_credits - 1'b1;
                default: model_credits = model_credits;
            endcase

            #1;
            if (credits !== model_credits)
                $fatal(1, "credit count mismatch: RTL=%0d model=%0d", credits, model_credits);
        end
    endtask

    initial begin
        repeat (2) @(negedge clk);
        rst_n = 1;
        for (cycle = 0; cycle < 500; cycle = cycle + 1) begin
            @(negedge clk);
            if (!pending_input && (($random(seed) & 3) != 0)) begin
                pending_input = 1;
                pending_input_data = $random(seed);
            end
            s_valid = pending_input;
            s_data = pending_input_data;
            link_up = (($random(seed) & 3) != 0);
            m_ready = (($random(seed) & 3) != 0);
            credit_return = (($random(seed) & 1) != 0);
            #1;

            if (!rate_profile_supported || configured_rate_gt_s !== RATE_PROFILE_GT_S)
                $fatal(1, "profile %0d GT/s was not propagated", RATE_PROFILE_GT_S);
            if (!link_up && (s_ready || m_valid))
                $fatal(1, "interface handshake enabled while link was down");
            if (held_output_stalled && link_up &&
                (!m_valid || m_data !== held_output_data))
                $fatal(1, "stalled output changed while the link stayed active");

            held_output_stalled = link_up && m_valid && !m_ready;
            held_output_data = m_data;
            sample_cycle();
        end

        // Stop generating traffic, keep the source word stable until accepted,
        // and drain the adapter with just enough credit to make progress.
        drain_cycle = 0;
        while (drain_cycle < 4096 &&
               (pending_input || received != sent || dut.buffered_valid)) begin
            @(negedge clk);
            link_up = 1;
            m_ready = 1;
            credit_return = (credits == 0);
            s_valid = pending_input;
            s_data = pending_input_data;
            held_output_stalled = 0;
            sample_cycle();
            drain_cycle = drain_cycle + 1;
        end

        if (pending_input || received != sent || dut.buffered_valid)
            $fatal(1, "drain timeout: sent=%0d received=%0d", sent, received);
        if (sent < 100)
            $fatal(1, "random run did not exercise enough traffic: %0d", sent);
        $display("PASS random stream profile=%0d GT/s: %0d transactions", RATE_PROFILE_GT_S, received);
        $finish;
    end

    initial begin
        #100000;
        $fatal(1, "timeout in random stream profile %0d GT/s", RATE_PROFILE_GT_S);
    end
endmodule
