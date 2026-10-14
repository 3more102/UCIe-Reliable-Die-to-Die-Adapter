module tb_reliable_stream_model;
    parameter integer RATE_PROFILE_GT_S = 64;
    parameter integer MAX_RETRIES = 3;
    parameter integer RESPONSE_TIMEOUT_CYCLES = 4;

    reg clk = 0;
    always #5 clk = ~clk;

    reg rst_n = 0;
    reg link_start = 0;
    reg training_done = 0;
    reg fault = 0;
    reg recovery_done = 0;
    reg [31:0] s_data = 0;
    reg s_valid = 0;
    wire s_ready;
    wire [31:0] m_data;
    wire m_valid;
    reg m_ready = 0;
    reg credit_return = 0;
    reg phy_ready = 1;
    reg corrupt_crc = 0;
    reg drop_frame = 0;
    reg drop_response = 0;
    wire profile_supported;
    wire [7:0] rate_profile_gt_s;
    wire link_up;
    wire [1:0] link_state;
    wire [3:0] credits;
    wire tx_busy;
    wire retry_failed;
    wire [7:0] retry_count;
    wire crc_error;
    wire [1:0] crc_error_count;
    wire [1:0] response_timeout_count;
    wire [1:0] link_recovery_count;
    integer i;
    integer timeout;
    integer error_count;

    reliable_stream_model #(
        .DATA_WIDTH(32),
        .CREDIT_WIDTH(4),
        .MAX_RETRIES(MAX_RETRIES),
        .RESPONSE_TIMEOUT_CYCLES(RESPONSE_TIMEOUT_CYCLES),
        .STATUS_COUNT_WIDTH(2),
        .RATE_PROFILE_GT_S(RATE_PROFILE_GT_S)
    ) dut (
        .clk(clk),
        .rst_n(rst_n),
        .link_start_i(link_start),
        .training_done_i(training_done),
        .fault_i(fault),
        .recovery_done_i(recovery_done),
        .s_data_i(s_data),
        .s_valid_i(s_valid),
        .s_ready_o(s_ready),
        .m_data_o(m_data),
        .m_valid_o(m_valid),
        .m_ready_i(m_ready),
        .credit_return_i(credit_return),
        .phy_ready_i(phy_ready),
        .corrupt_crc_i(corrupt_crc),
        .drop_frame_i(drop_frame),
        .drop_response_i(drop_response),
        .profile_supported_o(profile_supported),
        .rate_profile_gt_s_o(rate_profile_gt_s),
        .link_up_o(link_up),
        .link_state_o(link_state),
        .credits_o(credits),
        .tx_busy_o(tx_busy),
        .retry_failed_o(retry_failed),
        .retry_count_o(retry_count),
        .crc_error_o(crc_error),
        .crc_error_count_o(crc_error_count),
        .response_timeout_count_o(response_timeout_count),
        .link_recovery_count_o(link_recovery_count)
    );

    task start_link;
        begin
            @(negedge clk); link_start = 1;
            @(negedge clk); link_start = 0; training_done = 1;
            @(negedge clk); training_done = 0;
            if (RATE_PROFILE_GT_S == 48 || RATE_PROFILE_GT_S == 64) begin
                if (!link_up) $fatal(1, "profile %0d did not enter active", RATE_PROFILE_GT_S);
            end else begin
                if (link_up) $fatal(1, "unsupported profile reported link up");
            end
        end
    endtask

    task send_payload(input [31:0] value);
        begin
            @(negedge clk);
            if (!s_ready) $fatal(1, "source not ready for payload %08x", value);
            s_data = value;
            s_valid = 1;
            @(negedge clk);
            s_valid = 0;
        end
    endtask

    task grant_credit;
        begin
            @(negedge clk); credit_return = 1;
            @(negedge clk); credit_return = 0;
        end
    endtask

    task wait_for_crc_error;
        integer timeout;
        begin
            timeout = 0;
            while (!crc_error && timeout < 30) begin
                @(negedge clk);
                timeout = timeout + 1;
            end
            if (!crc_error) $fatal(1, "timed out waiting for CRC error at profile %0d", RATE_PROFILE_GT_S);
            error_count = error_count + 1;
        end
    endtask

    task wait_for_delivery(input [31:0] expected);
        integer timeout;
        begin
            timeout = 0;
            while (!m_valid && timeout < 30) begin
                @(negedge clk);
                timeout = timeout + 1;
            end
            if (!m_valid) $fatal(1, "timed out waiting for delivered payload %08x", expected);
            if (m_data !== expected)
                $fatal(1, "delivered payload mismatch: got %08x expected %08x", m_data, expected);
        end
    endtask

    initial begin
        error_count = 0;
        i = 0;
        timeout = 0;
        repeat (3) @(negedge clk);
        rst_n = 1;
        start_link();

        if ((RATE_PROFILE_GT_S == 48 || RATE_PROFILE_GT_S == 64) &&
            rate_profile_gt_s !== RATE_PROFILE_GT_S[7:0])
            $fatal(1, "supported profile metadata mismatch: got %0d expected %0d",
                   rate_profile_gt_s, RATE_PROFILE_GT_S);
        if (!(RATE_PROFILE_GT_S == 48 || RATE_PROFILE_GT_S == 64) && rate_profile_gt_s !== 0)
            $fatal(1, "unsupported profile must report effective profile zero, got %0d", rate_profile_gt_s);

        if (!(RATE_PROFILE_GT_S == 48 || RATE_PROFILE_GT_S == 64)) begin
            if (profile_supported || s_ready)
                $fatal(1, "unsupported profile accepted traffic");
            $display("PASS tb_reliable_stream_model unsupported profile %0d rejected", RATE_PROFILE_GT_S);
            $finish;
        end

        if (!profile_supported) $fatal(1, "supported profile %0d rejected", RATE_PROFILE_GT_S);

        // The sender accepts one packet locally, then stalls until it has credit.
        send_payload(32'hA55A_1234);
        if (!tx_busy || credits != 0 || m_valid)
            $fatal(1, "packet did not wait for credit as expected");

        // A corrupted attempt is NACKed and not delivered. The retry remains
        // blocked until a fresh project-defined credit return.
        corrupt_crc = 1;
        phy_ready = 0;
        grant_credit();
        repeat (3) begin
            @(negedge clk);
            if (credits != 1 || m_valid || crc_error || !tx_busy)
                $fatal(1, "PHY backpressure state credits=%0d m_valid=%b crc_error=%b tx_busy=%b",
                       credits, m_valid, crc_error, tx_busy);
        end
        phy_ready = 1;
        wait_for_crc_error();
        timeout = 0;
        while (retry_count != 1 && timeout < 30) begin
            @(negedge clk);
            timeout = timeout + 1;
        end
        if (retry_count != 1 || !tx_busy || m_valid || credits != 0)
            $fatal(1, "NACK/retry/credit behavior mismatch");
        corrupt_crc = 0;
        repeat (3) @(negedge clk);
        if (m_valid || credits != 0)
            $fatal(1, "retry bypassed credit starvation");
        grant_credit();
        wait_for_delivery(32'hA55A_1234);
        while (tx_busy && i < 60) begin @(negedge clk); i = i + 1; end
        if (tx_busy || retry_failed)
            $fatal(1, "valid retry was not acknowledged");
        repeat (3) begin
            @(negedge clk);
            if (!m_valid || m_data !== 32'hA55A_1234)
                $fatal(1, "receive data was not held under backpressure");
        end
        m_ready = 1;
        @(negedge clk); m_ready = 0;
        if (m_valid) $fatal(1, "receive buffer did not release after handshake");

        // Fault on the same sampled edge that the abstract channel accepts a
        // frame. The receiver stores its ACK while the link goes down; the
        // transmitter must complete from that retained response after recovery.
        grant_credit();
        send_payload(32'h1357_9BDF);
        timeout = 0;
        while (!(dut.credit_s_valid && dut.credit_m_ready) && timeout < 30) begin
            @(negedge clk);
            timeout = timeout + 1;
        end
        if (!(dut.credit_s_valid && dut.credit_m_ready))
            $fatal(1, "timed out waiting for in-flight frame handshake");
        fault = 1;
        @(negedge clk); fault = 0;
        if (link_up || !tx_busy || !m_valid || m_data !== 32'h1357_9BDF ||
            !dut.rx_integrity.response_valid_q)
            $fatal(1, "frame/ACK state was not retained at the link-fault boundary");
        repeat (2) begin
            @(negedge clk);
            if (link_up || !tx_busy || !m_valid || m_data !== 32'h1357_9BDF)
                $fatal(1, "in-flight frame state changed during recovery");
        end
        @(negedge clk); recovery_done = 1;
        @(negedge clk); recovery_done = 0; training_done = 1;
        @(negedge clk); training_done = 0;
        if (!link_up) $fatal(1, "link did not recover after in-flight frame fault");
        timeout = 0;
        while (tx_busy && timeout < 30) begin
            @(negedge clk);
            timeout = timeout + 1;
        end
        if (tx_busy || !m_valid || m_data !== 32'h1357_9BDF)
            $fatal(1, "retained ACK did not retire replay without losing receive data");
        if (link_recovery_count != 1)
            $fatal(1, "link recovery counter did not record the in-flight recovery");
        m_ready = 1;
        @(posedge clk);
        @(negedge clk); m_ready = 0;
        if (m_valid) $fatal(1, "in-flight recovered frame was delivered more than once");

        // Lose one valid ACK at the abstract digital boundary. The sender's
        // project-defined model-cycle timeout schedules a replay, which is
        // duplicate-suppressed by RX and must not redeliver the payload.
        grant_credit();
        drop_response = 1;
        send_payload(32'hC0DE_64A5);
        timeout = 0;
        while (!(dut.rx_response_valid && dut.tx_response_ready) && timeout < 30) begin
            @(negedge clk);
            timeout = timeout + 1;
        end
        if (!(dut.rx_response_valid && dut.tx_response_ready))
            $fatal(1, "timed out waiting for response-loss injection point");
        @(posedge clk);
        @(negedge clk);
        if (dut.rx_response_valid || !tx_busy || retry_count != 0 ||
            !m_valid || m_data !== 32'hC0DE_64A5 || credits != 0)
            $fatal(1, "dropped ACK did not leave replay waiting with RX data retained");
        drop_response = 0;
        timeout = 0;
        while (retry_count != 1 && timeout < 30) begin
            @(negedge clk);
            timeout = timeout + 1;
        end
        if (retry_count != 1 || !tx_busy || !m_valid || credits != 0)
            $fatal(1, "response timeout did not schedule a credit-gated replay");
        grant_credit();
        timeout = 0;
        while (tx_busy && timeout < 30) begin
            @(negedge clk);
            timeout = timeout + 1;
        end
        if (tx_busy || !m_valid || m_data !== 32'hC0DE_64A5)
            $fatal(1, "duplicate ACK after timeout did not retire replay exactly once");
        if (response_timeout_count != 1)
            $fatal(1, "response timeout counter did not record the dropped ACK");
        m_ready = 1;
        @(negedge clk); m_ready = 0;
        if (m_valid) $fatal(1, "response-loss replay delivered the payload twice");

        // Drop one accepted abstract channel frame before RX sees it. The
        // sender must time out, wait for a fresh credit, and deliver once.
        grant_credit();
        drop_frame = 1;
        send_payload(32'hD09F_64A5);
        timeout = 0;
        while (!(dut.credit_s_valid && dut.credit_m_ready) && timeout < 30) begin
            @(negedge clk);
            timeout = timeout + 1;
        end
        if (!(dut.credit_s_valid && dut.credit_m_ready))
            $fatal(1, "timed out waiting for frame-loss injection point");
        @(posedge clk);
        @(negedge clk);
        drop_frame = 0;
        if (m_valid || dut.rx_response_valid || !tx_busy || credits != 0)
            $fatal(1, "dropped frame reached RX or was not charged a credit");
        timeout = 0;
        while (retry_count != 1 && timeout < 30) begin
            @(negedge clk);
            timeout = timeout + 1;
        end
        if (retry_count != 1 || m_valid || credits != 0)
            $fatal(1, "frame-loss timeout did not schedule a credit-gated retry");
        grant_credit();
        wait_for_delivery(32'hD09F_64A5);
        timeout = 0;
        while (tx_busy && timeout < 30) begin
            @(negedge clk);
            timeout = timeout + 1;
        end
        if (tx_busy || !m_valid || m_data !== 32'hD09F_64A5)
            $fatal(1, "frame-loss retry was not acknowledged exactly once");
        if (response_timeout_count != 2)
            $fatal(1, "frame-loss timeout counter mismatch: got %0d expected 2",
                   response_timeout_count);
        m_ready = 1;
        @(negedge clk); m_ready = 0;
        if (m_valid) $fatal(1, "frame-loss retry delivered the payload twice");

        // Drop link while a packet waits for a credit; it must survive recovery.
        send_payload(32'hDEAD_BEEF);
        @(negedge clk); fault = 1;
        @(negedge clk); fault = 0;
        if (link_up || !tx_busy) $fatal(1, "fault did not enter recovery or packet was lost");
        @(negedge clk); recovery_done = 1;
        @(negedge clk); recovery_done = 0; training_done = 1;
        @(negedge clk); training_done = 0;
        if (!link_up || !tx_busy) $fatal(1, "packet did not survive link recovery");
        if (link_recovery_count != 2)
            $fatal(1, "link recovery counter mismatch after second recovery");
        grant_credit();
        wait_for_delivery(32'hDEAD_BEEF);
        m_ready = 1;
        @(negedge clk); m_ready = 0;
        if (m_valid) $fatal(1, "recovered packet was not consumed");

        // A reset clears the complete digital path, including a pending replay.
        send_payload(32'hFACE_FEED);
        if (!tx_busy) $fatal(1, "pre-reset packet was not retained");
        @(negedge clk);
        rst_n = 0;
        link_start = 0;
        training_done = 0;
        fault = 0;
        recovery_done = 0;
        credit_return = 0;
        corrupt_crc = 0;
        repeat (2) @(negedge clk);
        if (link_up || tx_busy || credits != 0 || m_valid || retry_failed ||
            crc_error_count != 0 || response_timeout_count != 0 || link_recovery_count != 0)
            $fatal(1, "reset did not clear link, replay, credit, and receive state");
        rst_n = 1;
        start_link();
        send_payload(32'h0123_4567);
        send_payload(32'h7654_3210);
        if (!tx_busy || s_ready)
            $fatal(1, "ingress queue did not retain the second ordered payload");
        grant_credit();
        wait_for_delivery(32'h0123_4567);
        m_ready = 1;
        @(negedge clk); m_ready = 0;
        if (m_valid) $fatal(1, "post-reset data was not consumed");
        if (!tx_busy || credits != 0)
            $fatal(1, "second post-reset frame was not retained in ingress");
        grant_credit();
        wait_for_delivery(32'h7654_3210);
        timeout = 0;
        while (tx_busy && timeout < 30) begin
            @(negedge clk);
            timeout = timeout + 1;
        end
        if (tx_busy) $fatal(1, "queued second frame was not acknowledged");
        m_ready = 1;
        @(negedge clk); m_ready = 0;
        if (m_valid) $fatal(1, "second queued payload was not consumed");

        // Exhaust the project-local retry limit: every bad attempt is dropped.
        send_payload(32'hBAD0_CAFE);
        corrupt_crc = 1;
        for (i = 0; i <= MAX_RETRIES; i = i + 1) begin
            grant_credit();
            wait_for_crc_error();
            if (i < MAX_RETRIES) begin
                timeout = 0;
                while (retry_count != i + 1 && timeout < 30) begin
                    @(negedge clk);
                    timeout = timeout + 1;
                end
                if (retry_count != i + 1)
                    $fatal(1, "retry count did not advance after NACK");
            end
        end
        timeout = 0;
        while (!retry_failed && timeout < 30) begin
            @(negedge clk);
            timeout = timeout + 1;
        end
        if (!retry_failed || retry_count != MAX_RETRIES || m_valid)
            $fatal(1, "retry exhaustion did not fail closed");
        if (error_count != (MAX_RETRIES + 2))
            $fatal(1, "unexpected CRC error count %0d", error_count);
        if (crc_error_count != 2'b11 || response_timeout_count != 0 || link_recovery_count != 0)
            $fatal(1, "saturating status counters mismatch crc=%0d timeout=%0d recovery=%0d",
                   crc_error_count, response_timeout_count, link_recovery_count);

        $display("PASS tb_reliable_stream_model profile=%0d simulated attempts=%0d", RATE_PROFILE_GT_S, error_count);
        $finish;
    end
endmodule
