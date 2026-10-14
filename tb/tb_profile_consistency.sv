// Confirms the generic stream and reliability model use the same digital
// 48/64 profile selection and fail-closed unsupported-profile indication.
// This checks configuration consistency, not physical line-rate behavior.
module tb_profile_consistency;
    parameter integer RATE_PROFILE_GT_S = 64;

    reg clk = 0;
    always #5 clk = ~clk;

    reg rst_n = 0;
    reg stream_link_up = 0;
    reg model_link_start = 0;
    reg model_training_done = 0;
    reg model_fault = 0;
    reg model_recovery_done = 0;
    reg [7:0] s_data = 0;
    reg s_valid = 0;
    reg stream_m_ready = 0;
    reg model_m_ready = 0;
    reg credit_return = 0;

    wire stream_s_ready;
    wire [7:0] stream_m_data;
    wire stream_m_valid;
    wire [1:0] stream_credits;
    wire stream_profile_supported;
    wire [6:0] stream_profile_gt_s;

    wire model_s_ready;
    wire [7:0] model_m_data;
    wire model_m_valid;
    wire model_profile_supported;
    wire [7:0] model_profile_gt_s;
    wire model_link_up;
    wire [1:0] model_link_state;
    wire [1:0] model_credits;
    wire model_tx_busy;
    wire model_retry_failed;
    wire [7:0] model_retry_count;
    wire model_crc_error;
    wire [15:0] model_crc_error_count;
    wire [15:0] model_timeout_count;
    wire [15:0] model_recovery_count;
    integer timeout;

    stream_adapter #(
        .WIDTH(8), .CREDIT_WIDTH(2), .RATE_PROFILE_GT_S(RATE_PROFILE_GT_S)
    ) stream_dut (
        .clk(clk), .rst_n(rst_n), .link_up(stream_link_up),
        .s_data(s_data), .s_valid(s_valid), .s_ready(stream_s_ready),
        .m_data(stream_m_data), .m_valid(stream_m_valid),
        .m_ready(stream_m_ready), .credit_return(credit_return),
        .credits(stream_credits),
        .rate_profile_supported(stream_profile_supported),
        .configured_rate_gt_s(stream_profile_gt_s)
    );

    reliable_stream_model #(
        .DATA_WIDTH(8), .CREDIT_WIDTH(2), .MAX_RETRIES(1),
        .RESPONSE_TIMEOUT_CYCLES(4), .STATUS_COUNT_WIDTH(16),
        .RATE_PROFILE_GT_S(RATE_PROFILE_GT_S)
    ) reliability_dut (
        .clk(clk), .rst_n(rst_n),
        .link_start_i(model_link_start), .training_done_i(model_training_done),
        .fault_i(model_fault), .recovery_done_i(model_recovery_done),
        .s_data_i(s_data), .s_valid_i(s_valid), .s_ready_o(model_s_ready),
        .m_data_o(model_m_data), .m_valid_o(model_m_valid),
        .m_ready_i(model_m_ready), .credit_return_i(credit_return),
        .phy_ready_i(1'b1), .corrupt_crc_i(1'b0), .drop_frame_i(1'b0),
        .drop_response_i(1'b0),
        .profile_supported_o(model_profile_supported),
        .rate_profile_gt_s_o(model_profile_gt_s), .link_up_o(model_link_up),
        .link_state_o(model_link_state), .credits_o(model_credits),
        .tx_busy_o(model_tx_busy), .retry_failed_o(model_retry_failed),
        .retry_count_o(model_retry_count), .crc_error_o(model_crc_error),
        .crc_error_count_o(model_crc_error_count),
        .response_timeout_count_o(model_timeout_count),
        .link_recovery_count_o(model_recovery_count)
    );

    initial begin
        repeat (3) @(negedge clk);
        rst_n = 1;
        stream_link_up = 1;
        @(negedge clk); model_link_start = 1;
        @(negedge clk); model_link_start = 0; model_training_done = 1;
        @(negedge clk); model_training_done = 0;

        if (stream_profile_supported !== model_profile_supported)
            $fatal(1, "profile support mismatch between stream and reliability model");
        if (stream_profile_gt_s !== model_profile_gt_s)
            $fatal(1, "effective profile mismatch stream=%0d reliability=%0d",
                   stream_profile_gt_s, model_profile_gt_s);

        if (RATE_PROFILE_GT_S == 48 || RATE_PROFILE_GT_S == 64) begin
            if (!stream_profile_supported || !model_profile_supported ||
                stream_profile_gt_s !== RATE_PROFILE_GT_S[6:0] ||
                model_profile_gt_s !== RATE_PROFILE_GT_S[7:0] ||
                !stream_s_ready || !model_s_ready || !model_link_up)
                $fatal(1, "supported profile %0d did not activate consistently", RATE_PROFILE_GT_S);

            // One generic credit on each side allows the same word to pass
            // through both single-clock digital datapaths.
            credit_return = 1;
            @(negedge clk); credit_return = 0;
            s_data = 8'hA6; s_valid = 1;
            @(posedge clk);
            @(negedge clk); s_valid = 0;

            timeout = 0;
            while ((!stream_m_valid || !model_m_valid) && timeout < 30) begin
                @(negedge clk);
                timeout = timeout + 1;
            end
            if (!stream_m_valid || !model_m_valid || stream_m_data !== 8'hA6 ||
                model_m_data !== 8'hA6)
                $fatal(1, "profile %0d datapaths did not preserve the same transaction", RATE_PROFILE_GT_S);
            repeat (2) begin
                @(negedge clk);
                if (!stream_m_valid || !model_m_valid || stream_m_data !== 8'hA6 ||
                    model_m_data !== 8'hA6)
                    $fatal(1, "profile %0d datapath output changed under backpressure", RATE_PROFILE_GT_S);
            end
            stream_m_ready = 1;
            model_m_ready = 1;
            @(posedge clk);
            @(negedge clk);
            if (stream_m_valid || model_m_valid)
                $fatal(1, "profile %0d transaction was not consumed exactly once", RATE_PROFILE_GT_S);
            $display("PASS shared profile=%0d GT/s (digital configuration and datapath)", RATE_PROFILE_GT_S);
        end else begin
            if (stream_profile_supported || model_profile_supported ||
                stream_profile_gt_s !== 0 || model_profile_gt_s !== 0 ||
                stream_s_ready || model_s_ready || model_link_up)
                $fatal(1, "unsupported profile %0d was not rejected consistently", RATE_PROFILE_GT_S);
            s_data = 8'h5A; s_valid = 1;
            @(posedge clk);
            @(negedge clk); s_valid = 0;
            if (stream_m_valid || model_m_valid)
                $fatal(1, "unsupported profile %0d captured traffic", RATE_PROFILE_GT_S);
            $display("PASS shared unsupported profile=%0d GT/s rejected", RATE_PROFILE_GT_S);
        end
        $finish;
    end

    initial begin
        #2000;
        $fatal(1, "profile consistency test timed out at %0d GT/s", RATE_PROFILE_GT_S);
    end
endmodule
