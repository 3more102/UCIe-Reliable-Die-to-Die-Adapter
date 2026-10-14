module tb_generic_replay_tx;
    localparam integer DATA_WIDTH = 16;
    localparam integer MAX_RETRIES = 2;
    localparam integer RESPONSE_TIMEOUT_CYCLES = 4;

    reg clk = 0;
    always #5 clk = ~clk;

    reg rst_n = 0;
    reg link_active = 0;
    reg [DATA_WIDTH-1:0] s_data = 0;
    reg s_valid = 0;
    wire s_ready;
    wire [DATA_WIDTH-1:0] frame_data;
    wire [15:0] frame_crc;
    wire frame_seq;
    wire frame_valid;
    reg frame_ready = 0;
    reg response_valid = 0;
    wire response_ready;
    reg response_ack = 0;
    reg response_seq = 0;
    wire busy;
    wire failed;
    wire [7:0] retry_count;
    reg no_timeout_s_valid = 0;
    reg [DATA_WIDTH-1:0] no_timeout_s_data = 0;
    reg no_timeout_frame_ready = 0;
    wire no_timeout_s_ready;
    wire no_timeout_frame_valid;
    wire no_timeout_response_ready;
    wire no_timeout_busy;
    wire no_timeout_failed;
    wire [7:0] no_timeout_retry_count;
    integer attempt;
    integer timeout;

    generic_replay_tx #(
        .DATA_WIDTH(DATA_WIDTH),
        .MAX_RETRIES(MAX_RETRIES),
        .RESPONSE_TIMEOUT_CYCLES(RESPONSE_TIMEOUT_CYCLES)
    ) dut (
        .clk(clk), .rst_n(rst_n), .link_active_i(link_active),
        .s_data_i(s_data), .s_valid_i(s_valid), .s_ready_o(s_ready),
        .frame_data_o(frame_data), .frame_crc_o(frame_crc),
        .frame_seq_o(frame_seq), .frame_valid_o(frame_valid),
        .frame_ready_i(frame_ready), .response_valid_i(response_valid),
        .response_ready_o(response_ready), .response_ack_i(response_ack),
        .response_seq_i(response_seq), .busy_o(busy), .failed_o(failed),
        .retry_count_o(retry_count)
    );

    generic_replay_tx #(
        .DATA_WIDTH(DATA_WIDTH),
        .MAX_RETRIES(MAX_RETRIES),
        .RESPONSE_TIMEOUT_CYCLES(0)
    ) dut_timeout_disabled (
        .clk(clk), .rst_n(rst_n), .link_active_i(link_active),
        .s_data_i(no_timeout_s_data), .s_valid_i(no_timeout_s_valid),
        .s_ready_o(no_timeout_s_ready), .frame_data_o(), .frame_crc_o(),
        .frame_seq_o(), .frame_valid_o(no_timeout_frame_valid),
        .frame_ready_i(no_timeout_frame_ready), .response_valid_i(1'b0),
        .response_ready_o(no_timeout_response_ready), .response_ack_i(1'b0),
        .response_seq_i(1'b0), .busy_o(no_timeout_busy),
        .failed_o(no_timeout_failed), .retry_count_o(no_timeout_retry_count)
    );

    task accept_payload(input [DATA_WIDTH-1:0] value);
        begin
            @(negedge clk);
            s_data = value;
            s_valid = 1;
            if (!s_ready) $fatal(1, "sender not ready for payload %h", value);
            @(posedge clk);
            @(negedge clk);
            s_valid = 0;
            if (!frame_valid || frame_data !== value || !busy)
                $fatal(1, "accepted payload was not retained for replay");
        end
    endtask

    task handshake_frame(input [DATA_WIDTH-1:0] expected_data,
                         input bit expected_seq);
        reg [15:0] held_crc;
        begin
            frame_ready = 0;
            if (!frame_valid || frame_data !== expected_data || frame_seq !== expected_seq)
                $fatal(1, "frame mismatch valid=%b data=%h seq=%b expected=%h/%b",
                       frame_valid, frame_data, frame_seq, expected_data, expected_seq);
            held_crc = frame_crc;
            // Changes on the source must not alter a stalled replay attempt.
            s_data = ~expected_data;
            repeat (2) begin
                @(negedge clk);
                if (!frame_valid || frame_data !== expected_data ||
                    frame_seq !== expected_seq || frame_crc !== held_crc)
                    $fatal(1, "stalled replay frame changed under backpressure");
            end
            frame_ready = 1;
            @(posedge clk);
            @(negedge clk);
            frame_ready = 0;
            if (frame_valid || !busy || !response_ready)
                $fatal(1, "sender did not wait for response after frame handshake");
        end
    endtask

    task send_response(input bit ack_value, input bit seq_value);
        begin
            @(negedge clk);
            response_ack = ack_value;
            response_seq = seq_value;
            response_valid = 1;
            if (!response_ready) $fatal(1, "sender not ready for response");
            @(posedge clk);
            @(negedge clk);
            response_valid = 0;
        end
    endtask

    initial begin
        repeat (2) @(negedge clk);
        rst_n = 1;
        link_active = 1;

        // Wrong-sequence ACK is ignored, as is a matching ACK while the
        // project-local link-active qualifier is low.
        accept_payload(16'hA55A);
        handshake_frame(16'hA55A, 1'b0);
        @(negedge clk);
        response_valid = 1;
        response_ack = 1;
        response_seq = 1'b1;
        @(posedge clk);
        @(negedge clk);
        response_valid = 0;
        if (!busy || !response_ready || retry_count != 0)
            $fatal(1, "wrong-sequence ACK changed sender state");

        link_active = 0;
        response_valid = 1;
        response_ack = 1;
        response_seq = 1'b0;
        repeat (2) begin
            @(negedge clk);
            if (response_ready || !busy)
                $fatal(1, "link-down response was accepted or packet was lost");
        end
        response_valid = 0;
        link_active = 1;
        send_response(1'b0, 1'b0);
        if (retry_count != 1 || !frame_valid || !busy)
            $fatal(1, "matching NACK did not schedule exactly one retry");
        handshake_frame(16'hA55A, 1'b0);
        send_response(1'b1, 1'b0);
        if (busy || failed || retry_count != 1)
            $fatal(1, "matching ACK did not retire the packet cleanly");

        // Retry count is per packet. The configured limit permits exactly two
        // retransmissions; the next NACK enters sticky FAILED state.
        accept_payload(16'hC33C);
        handshake_frame(16'hC33C, 1'b1);
        send_response(1'b0, 1'b1);
        if (retry_count != 1 || !frame_valid)
            $fatal(1, "first retry boundary mismatch");
        handshake_frame(16'hC33C, 1'b1);
        send_response(1'b0, 1'b1);
        if (retry_count != MAX_RETRIES || !frame_valid)
            $fatal(1, "second retry boundary mismatch");
        handshake_frame(16'hC33C, 1'b1);
        send_response(1'b0, 1'b1);
        if (!failed || busy || frame_valid || retry_count != MAX_RETRIES)
            $fatal(1, "retry exhaustion did not fail closed at configured limit");

        @(negedge clk);
        response_valid = 0;
        s_valid = 0;
        repeat (3) begin
            @(negedge clk);
            if (!failed || busy || s_ready)
                $fatal(1, "FAILED state was not sticky until reset");
        end
        rst_n = 0;
        repeat (2) @(negedge clk);
        if (failed || busy || retry_count != 0)
            $fatal(1, "reset did not clear failed state and retry count");
        rst_n = 1;
        @(negedge clk);
        if (!s_ready)
            $fatal(1, "sender did not accept a new packet after reset");

        // Response time is counted in project model cycles and pauses while
        // link_active is low. Two active cycles plus a long link-down interval
        // must leave exactly two active cycles before the retry is scheduled.
        accept_payload(16'h5AA5);
        handshake_frame(16'h5AA5, 1'b0);
        repeat (2) @(posedge clk);
        @(negedge clk);
        if (!response_ready || retry_count != 0 || frame_valid)
            $fatal(1, "response timeout expired before its configured boundary");
        link_active = 0;
        repeat (5) begin
            @(posedge clk);
            @(negedge clk);
            if (response_ready || retry_count != 0 || frame_valid || !busy)
                $fatal(1, "response timer advanced or packet changed while link was down");
        end
        link_active = 1;
        @(posedge clk);
        @(negedge clk);
        if (retry_count != 0 || frame_valid)
            $fatal(1, "response timeout expired one active cycle early after recovery");
        @(posedge clk);
        @(negedge clk);
        if (retry_count != 1 || !frame_valid || !busy)
            $fatal(1, "response timeout did not schedule retry at exact active-cycle boundary");
        handshake_frame(16'h5AA5, 1'b0);
        send_response(1'b1, 1'b0);
        if (busy || failed || retry_count != 1)
            $fatal(1, "ACK after timeout retry did not retire packet");

        // A missing response on every attempt retries exactly MAX_RETRIES
        // times, then enters sticky FAILED rather than waiting forever.
        accept_payload(16'hCAFE);
        for (attempt = 0; attempt <= MAX_RETRIES; attempt = attempt + 1) begin
            handshake_frame(16'hCAFE, 1'b1);
            timeout = 0;
            if (attempt < MAX_RETRIES) begin
                while (retry_count != attempt + 1 && timeout < RESPONSE_TIMEOUT_CYCLES + 3) begin
                    @(negedge clk);
                    timeout = timeout + 1;
                end
                if (retry_count != attempt + 1 || !frame_valid || !busy || failed)
                    $fatal(1, "timeout retry count/boundary mismatch on attempt %0d", attempt);
            end else begin
                while (!failed && timeout < RESPONSE_TIMEOUT_CYCLES + 3) begin
                    @(negedge clk);
                    timeout = timeout + 1;
                end
                if (!failed || busy || retry_count != MAX_RETRIES || frame_valid)
                    $fatal(1, "response-timeout exhaustion did not fail closed");
            end
        end

        // Zero is an explicit opt-out for integrations that supply their own
        // response supervision; no spontaneous retry may occur in that mode.
        @(negedge clk);
        no_timeout_s_data = 16'hD15A;
        no_timeout_s_valid = 1;
        @(posedge clk);
        @(negedge clk);
        no_timeout_s_valid = 0;
        if (!no_timeout_frame_valid || !no_timeout_busy)
            $fatal(1, "timeout-disabled sender did not retain its packet");
        no_timeout_frame_ready = 1;
        @(posedge clk);
        @(negedge clk);
        no_timeout_frame_ready = 0;
        repeat (RESPONSE_TIMEOUT_CYCLES + 2) begin
            @(posedge clk);
            @(negedge clk);
            if (!no_timeout_busy || no_timeout_failed || no_timeout_frame_valid ||
                no_timeout_retry_count != 0 || !no_timeout_response_ready)
                $fatal(1, "zero timeout did not disable autonomous retry");
        end

        $display("PASS tb_generic_replay_tx response, timeout boundary/pause/disable/exhaustion, backpressure, and fail-closed checks");
        $finish;
    end
endmodule
