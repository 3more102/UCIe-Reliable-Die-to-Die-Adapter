// Independent reference check for the generic stream adapter wrapper.
// The credit and buffering policy here is project-defined, not UCIe behavior.
module formal_stream_adapter;
    localparam integer WIDTH = 8;
    localparam integer CREDIT_WIDTH = 2;
    localparam [CREDIT_WIDTH-1:0] MAX_CREDITS = {CREDIT_WIDTH{1'b1}};

    (* gclk *) reg clk;
    initial clk = 0;
    always @($global_clock) clk <= !clk;

    (* anyseq *) reg rst_n;
    (* anyseq *) reg link_up;
    (* anyseq *) reg [WIDTH-1:0] s_data;
    (* anyseq *) reg s_valid;
    (* anyseq *) reg m_ready;
    (* anyseq *) reg credit_return;

    wire s_ready_48, m_valid_48, supported_48;
    wire [WIDTH-1:0] m_data_48;
    wire [CREDIT_WIDTH-1:0] credits_48;
    wire [6:0] rate_48;
    wire s_ready_64, m_valid_64, supported_64;
    wire [WIDTH-1:0] m_data_64;
    wire [CREDIT_WIDTH-1:0] credits_64;
    wire [6:0] rate_64;
    wire s_ready_32, m_valid_32, supported_32;
    wire [WIDTH-1:0] m_data_32;
    wire [CREDIT_WIDTH-1:0] credits_32;
    wire [6:0] rate_32;

    stream_adapter #(
        .WIDTH(WIDTH), .CREDIT_WIDTH(CREDIT_WIDTH), .RATE_PROFILE_GT_S(48)
    ) dut_48 (
        .clk(clk), .rst_n(rst_n), .link_up(link_up),
        .s_data(s_data), .s_valid(s_valid), .s_ready(s_ready_48),
        .m_data(m_data_48), .m_valid(m_valid_48), .m_ready(m_ready),
        .credit_return(credit_return), .credits(credits_48),
        .rate_profile_supported(supported_48), .configured_rate_gt_s(rate_48)
    );

    stream_adapter #(
        .WIDTH(WIDTH), .CREDIT_WIDTH(CREDIT_WIDTH), .RATE_PROFILE_GT_S(64)
    ) dut_64 (
        .clk(clk), .rst_n(rst_n), .link_up(link_up),
        .s_data(s_data), .s_valid(s_valid), .s_ready(s_ready_64),
        .m_data(m_data_64), .m_valid(m_valid_64), .m_ready(m_ready),
        .credit_return(credit_return), .credits(credits_64),
        .rate_profile_supported(supported_64), .configured_rate_gt_s(rate_64)
    );

    stream_adapter #(
        .WIDTH(WIDTH), .CREDIT_WIDTH(CREDIT_WIDTH), .RATE_PROFILE_GT_S(32)
    ) dut_unsupported (
        .clk(clk), .rst_n(rst_n), .link_up(link_up),
        .s_data(s_data), .s_valid(s_valid), .s_ready(s_ready_32),
        .m_data(m_data_32), .m_valid(m_valid_32), .m_ready(m_ready),
        .credit_return(credit_return), .credits(credits_32),
        .rate_profile_supported(supported_32), .configured_rate_gt_s(rate_32)
    );

    reg [CREDIT_WIDTH-1:0] ref_credits = 0;
    reg [WIDTH-1:0] ref_data = 0;
    reg ref_full = 0;
    wire active = rst_n && link_up;
    wire ref_output_valid = ref_full && active && (ref_credits != 0);
    wire ref_output_send = ref_output_valid && m_ready;
    wire ref_buffer_ready = active && m_ready && (ref_credits != 0);
    wire ref_ingress_ready = !ref_full || ref_buffer_ready;
    wire ref_input_ready = active && ref_ingress_ready;

    always @(posedge clk) begin
        if (!rst_n) begin
            ref_credits <= 0;
            ref_data <= 0;
            ref_full <= 0;
        end else begin
            assert(supported_48 && supported_64);
            assert(rate_48 == 48 && rate_64 == 64);
            assert(!supported_32 && rate_32 == 0);

            assert(s_ready_48 == ref_input_ready);
            assert(m_valid_48 == ref_output_valid);
            assert(m_data_48 == ref_data);
            assert(credits_48 == ref_credits);

            assert(s_ready_64 == s_ready_48);
            assert(m_valid_64 == m_valid_48);
            assert(m_data_64 == m_data_48);
            assert(credits_64 == credits_48);

            assert(!s_ready_32 && !m_valid_32 && credits_32 == 0);

            if (ref_ingress_ready) begin
                ref_full <= s_valid && active;
                if (s_valid && active)
                    ref_data <= s_data;
            end

            case ({credit_return && active, ref_output_send})
                2'b10: if (ref_credits != MAX_CREDITS)
                    ref_credits <= ref_credits + 1'b1;
                2'b01: ref_credits <= ref_credits - 1'b1;
                default: ref_credits <= ref_credits;
            endcase
        end
    end
endmodule
