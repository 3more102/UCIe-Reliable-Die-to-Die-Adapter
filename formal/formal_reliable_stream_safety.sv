// Bounded end-to-end ordering/integrity check for the project-local loopback.
// This is a digital safety property, not a UCIe protocol proof.
module formal_reliable_stream_safety;
    localparam integer DATA_WIDTH = 4;

    (* gclk *) reg clk;
    initial clk = 0;
    always @($global_clock) clk <= !clk;

    (* anyseq *) reg rst_n;
    (* anyseq *) reg fault;
    (* anyseq *) reg recovery_done;
    (* anyseq *) reg [DATA_WIDTH-1:0] s_data;
    (* anyseq *) reg s_valid;
    (* anyseq *) reg m_ready;
    (* anyseq *) reg credit_return;
    (* anyseq *) reg phy_ready;
    (* anyseq *) reg corrupt_crc;
    (* anyseq *) reg drop_response;

    wire s_ready;
    wire [DATA_WIDTH-1:0] m_data;
    wire m_valid;
    wire link_up;
    wire tx_busy;
    wire retry_failed;

    reliable_stream_model #(
        .DATA_WIDTH(DATA_WIDTH),
        .CREDIT_WIDTH(2),
        .MAX_RETRIES(1),
        .RESPONSE_TIMEOUT_CYCLES(3),
        .STATUS_COUNT_WIDTH(2),
        .RATE_PROFILE_GT_S(48)
    ) dut (
        .clk(clk), .rst_n(rst_n),
        .link_start_i(1'b1), .training_done_i(1'b1),
        .fault_i(fault), .recovery_done_i(recovery_done),
        .s_data_i(s_data), .s_valid_i(s_valid), .s_ready_o(s_ready),
        .m_data_o(m_data), .m_valid_o(m_valid), .m_ready_i(m_ready),
        .credit_return_i(credit_return), .phy_ready_i(phy_ready),
        .corrupt_crc_i(corrupt_crc), .drop_response_i(drop_response),
        .profile_supported_o(), .rate_profile_gt_s_o(), .link_up_o(link_up),
        .link_state_o(), .credits_o(), .tx_busy_o(tx_busy),
        .retry_failed_o(retry_failed), .retry_count_o(), .crc_error_o(),
        .crc_error_count_o(), .response_timeout_count_o(),
        .link_recovery_count_o()
    );

    // The architectural stream can hold at most three accepted words across
    // RX data, replay, and ingress storage. A four-entry reference queue leaves
    // one spare slot and checks that every delivered word was accepted first.
    reg [DATA_WIDTH-1:0] expected [0:3];
    reg [1:0] read_ptr = 0;
    reg [1:0] write_ptr = 0;
    reg [2:0] expected_count = 0;
    wire source_push = s_valid && s_ready;
    wire sink_pop = m_valid && m_ready;

    always @(posedge clk) begin
        if (!rst_n) begin
            read_ptr <= 0;
            write_ptr <= 0;
            expected_count <= 0;
        end else begin
            assert(link_up || !s_ready);
            if (sink_pop) begin
                assert(expected_count != 0);
                case (read_ptr)
                    2'd0: assert(m_data == expected[0]);
                    2'd1: assert(m_data == expected[1]);
                    2'd2: assert(m_data == expected[2]);
                    2'd3: assert(m_data == expected[3]);
                endcase
                read_ptr <= read_ptr + 1'b1;
            end
            if (source_push) begin
                assert(expected_count < 4 || sink_pop);
                case (write_ptr)
                    2'd0: expected[0] <= s_data;
                    2'd1: expected[1] <= s_data;
                    2'd2: expected[2] <= s_data;
                    2'd3: expected[3] <= s_data;
                endcase
                write_ptr <= write_ptr + 1'b1;
            end
            if (source_push && !sink_pop)
                expected_count <= expected_count + 1'b1;
            else if (!source_push && sink_pop)
                expected_count <= expected_count - 1'b1;
        end
    end
endmodule
