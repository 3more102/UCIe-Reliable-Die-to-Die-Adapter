module tb_reliable_stream_random;
    parameter integer RATE_PROFILE_GT_S = 64;
    parameter integer NUM_TRANSACTIONS = 24;
    localparam integer INJECTED_ERRORS = NUM_TRANSACTIONS / 4;

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
    reg phy_ready_random = 1;
    reg force_phy_stall = 0;
    wire phy_ready = phy_ready_random && !force_phy_stall;
    reg corrupt_crc = 0;
    wire profile_supported;
    wire [7:0] rate_profile_gt_s;
    wire link_up;
    wire [1:0] link_state;
    wire [3:0] credits;
    wire tx_busy;
    wire retry_failed;
    wire [7:0] retry_count;
    wire crc_error;
    reg randomize = 0;
    reg [31:0] lfsr = 32'h6D2B_79F5;
    reg source_handshake = 0;
    integer accepted_count = 0;
    integer delivered_count = 0;
    integer crc_error_count = 0;
    integer recovery_count = 0;
    integer cycle_count = 0;
    integer timeout;
    integer txn;

    reliable_stream_model #(
        .DATA_WIDTH(32),
        .CREDIT_WIDTH(4),
        .MAX_RETRIES(2),
        .RATE_PROFILE_GT_S(RATE_PROFILE_GT_S)
    ) dut (
        .clk(clk), .rst_n(rst_n),
        .link_start_i(link_start), .training_done_i(training_done),
        .fault_i(fault), .recovery_done_i(recovery_done),
        .s_data_i(s_data), .s_valid_i(s_valid), .s_ready_o(s_ready),
        .m_data_o(m_data), .m_valid_o(m_valid), .m_ready_i(m_ready),
        .credit_return_i(credit_return), .phy_ready_i(phy_ready),
        .corrupt_crc_i(corrupt_crc),
        .profile_supported_o(profile_supported),
        .rate_profile_gt_s_o(rate_profile_gt_s), .link_up_o(link_up),
        .link_state_o(link_state), .credits_o(credits), .tx_busy_o(tx_busy),
        .retry_failed_o(retry_failed), .retry_count_o(retry_count),
        .crc_error_o(crc_error)
    );

    function [31:0] expected_payload(input integer index);
        begin
            expected_payload = (index * 32'h9E37_79B9) ^ 32'hC3A5_5A3C;
        end
    endfunction

    // Deterministic cycle-by-cycle variation. Credits start empty and are
    // returned sparsely; readiness changes do not alter transaction payloads.
    always @(negedge clk) begin
        if (randomize) begin
            lfsr = {lfsr[30:0], lfsr[31] ^ lfsr[21] ^ lfsr[1] ^ lfsr[0]};
            phy_ready_random = lfsr[0] | lfsr[2];
            m_ready = lfsr[1];
            credit_return = (lfsr[3:0] == 4'hF);
        end
    end

    // Scoreboard samples the ready/valid handshakes at the active clock edge.
    always @(posedge clk) begin
        if (!rst_n) begin
            source_handshake = 0;
            accepted_count = 0;
            delivered_count = 0;
            crc_error_count = 0;
            cycle_count = 0;
        end else begin
            cycle_count = cycle_count + 1;
            if (s_valid && s_ready) begin
                source_handshake = 1;
                accepted_count = accepted_count + 1;
            end
            if (crc_error)
                crc_error_count = crc_error_count + 1;
            if (m_valid && m_ready) begin
                if (delivered_count >= accepted_count)
                    $fatal(1, "receiver produced an unaccepted transaction");
                if (m_data !== expected_payload(delivered_count))
                    $fatal(1, "order/data mismatch at receive index %0d: got %08x expected %08x",
                           delivered_count, m_data, expected_payload(delivered_count));
                delivered_count = delivered_count + 1;
            end
        end
    end

    task start_link;
        begin
            @(negedge clk); link_start = 1;
            @(negedge clk); link_start = 0; training_done = 1;
            @(negedge clk); training_done = 0;
            if (!link_up) $fatal(1, "profile %0d failed to start", RATE_PROFILE_GT_S);
        end
    endtask

    task recover_link_with_pending_frame;
        begin
            force_phy_stall = 1;
            @(negedge clk); fault = 1;
            @(negedge clk); fault = 0;
            if (link_up || !tx_busy)
                $fatal(1, "fault did not hold the accepted transaction in recovery");
            if (m_valid)
                $fatal(1, "pending pre-channel frame appeared at the receiver during recovery");

            @(negedge clk); recovery_done = 1;
            @(negedge clk); recovery_done = 0; training_done = 1;
            @(negedge clk); training_done = 0;
            timeout = 0;
            while (!link_up && timeout < 20) begin
                @(negedge clk);
                timeout = timeout + 1;
            end
            if (!link_up || !tx_busy)
                $fatal(1, "pending frame was not retained through link recovery");
            force_phy_stall = 0;
            recovery_count = recovery_count + 1;
        end
    endtask

    task send_transaction(input integer index);
        begin
            @(negedge clk);
            s_data = expected_payload(index);
            corrupt_crc = ((index % 4) == 1);
            s_valid = 1;
            timeout = 0;
            while (!source_handshake && timeout < 3000) begin
                @(negedge clk);
                timeout = timeout + 1;
            end
            if (!source_handshake)
                $fatal(1, "source timeout at transaction %0d", index);
            source_handshake = 0;
            s_valid = 0;

            // Recover while this accepted packet is held before the abstract
            // channel. Indices are selected deterministically and are not the
            // CRC-injection indices, so both fault paths remain distinguishable.
            if (index == 7 || index == 19)
                recover_link_with_pending_frame();

            if ((index % 4) == 1) begin
                timeout = 0;
                while (!crc_error && timeout < 3000) begin
                    @(negedge clk);
                    timeout = timeout + 1;
                end
                if (!crc_error)
                    $fatal(1, "injected CRC error was not detected at transaction %0d", index);
                corrupt_crc = 0;
                timeout = 0;
                while (retry_count != 1 && timeout < 3000) begin
                    @(negedge clk);
                    timeout = timeout + 1;
                end
                if (retry_count != 1)
                    $fatal(1, "retry was not recorded at transaction %0d", index);
            end

            timeout = 0;
            while (delivered_count <= index && timeout < 3000) begin
                @(negedge clk);
                timeout = timeout + 1;
            end
            if (delivered_count <= index)
                $fatal(1, "receiver timeout at transaction %0d", index);
            if (retry_failed)
                $fatal(1, "unexpected retry exhaustion at transaction %0d", index);
            corrupt_crc = 0;
        end
    endtask

    initial begin
        repeat (3) @(negedge clk);
        rst_n = 1;
        start_link();
        if (!profile_supported || rate_profile_gt_s !== RATE_PROFILE_GT_S[7:0])
            $fatal(1, "profile metadata/support mismatch");
        randomize = 1;

        for (txn = 0; txn < NUM_TRANSACTIONS; txn = txn + 1)
            send_transaction(txn);

        randomize = 0;
        corrupt_crc = 0;
        if (accepted_count != NUM_TRANSACTIONS || delivered_count != NUM_TRANSACTIONS)
            $fatal(1, "transaction totals mismatch accepted=%0d delivered=%0d",
                   accepted_count, delivered_count);
        if (crc_error_count != INJECTED_ERRORS)
            $fatal(1, "CRC error count mismatch got=%0d expected=%0d",
                   crc_error_count, INJECTED_ERRORS);
        if (recovery_count != 2)
            $fatal(1, "recovery count mismatch got=%0d expected=2", recovery_count);
        if (tx_busy || retry_failed)
            $fatal(1, "sender did not return to idle after randomized traffic");

        $display("PASS tb_reliable_stream_random profile=%0d accepted=%0d delivered=%0d injected_crc_errors=%0d recoveries=%0d cycles=%0d",
                 RATE_PROFILE_GT_S, accepted_count, delivered_count, crc_error_count, recovery_count, cycle_count);
        $finish;
    end
endmodule
