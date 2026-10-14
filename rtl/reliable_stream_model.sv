// Single-clock project-defined digital reliability model.
// RATE_PROFILE_GT_S is metadata/configuration only; this module does not
// create a GT/s clock, PHY, lane interface, or electrical link.
module reliable_stream_model #(
    parameter integer DATA_WIDTH = 64,
    parameter integer CREDIT_WIDTH = 8,
    parameter integer MAX_RETRIES = 2,
    parameter integer RATE_PROFILE_GT_S = 64
) (
    input  wire                  clk,
    input  wire                  rst_n,
    input  wire                  link_start_i,
    input  wire                  training_done_i,
    input  wire                  fault_i,
    input  wire                  recovery_done_i,
    input  wire [DATA_WIDTH-1:0] s_data_i,
    input  wire                  s_valid_i,
    output wire                  s_ready_o,
    output wire [DATA_WIDTH-1:0] m_data_o,
    output wire                  m_valid_o,
    input  wire                  m_ready_i,
    input  wire                  credit_return_i,
    input  wire                  phy_ready_i,
    input  wire                  corrupt_crc_i,
    output wire                  profile_supported_o,
    output wire [7:0]            rate_profile_gt_s_o,
    output wire                  link_up_o,
    output wire [1:0]            link_state_o,
    output wire [CREDIT_WIDTH-1:0] credits_o,
    output wire                  tx_busy_o,
    output wire                  retry_failed_o,
    output wire [7:0]            retry_count_o,
    output wire                  crc_error_o
);
    localparam integer FRAME_WIDTH = DATA_WIDTH + 17;
    localparam integer PROFILE_OK = (RATE_PROFILE_GT_S == 48) || (RATE_PROFILE_GT_S == 64);
    wire link_manager_up;
    wire active;
    wire [DATA_WIDTH-1:0] tx_frame_data;
    wire [15:0] tx_frame_crc;
    wire tx_frame_seq;
    wire tx_frame_valid;
    wire tx_frame_ready;
    wire tx_response_valid;
    wire tx_response_ready;
    wire tx_response_ack;
    wire tx_response_seq;
    wire [DATA_WIDTH-1:0] ingress_data;
    wire ingress_valid;
    wire ingress_ready;
    wire replay_s_ready;
    wire replay_busy;
    wire [FRAME_WIDTH-1:0] credit_s_data;
    wire [FRAME_WIDTH-1:0] credit_m_data;
    wire credit_s_valid;
    wire credit_s_ready;
    wire credit_m_valid;
    wire credit_m_ready;
    wire [DATA_WIDTH-1:0] rx_data;
    wire [15:0] rx_frame_crc;
    wire rx_valid;
    wire rx_ready;
    wire rx_response_valid;
    wire rx_response_ack;
    wire rx_response_seq;
    wire crc_error;

    assign profile_supported_o = PROFILE_OK[0];
    assign rate_profile_gt_s_o = RATE_PROFILE_GT_S[7:0];
    assign active = link_manager_up && profile_supported_o;
    assign link_up_o = active;
    assign s_ready_o = active && ingress_ready;
    assign tx_busy_o = replay_busy || ingress_valid;
    assign credit_s_data = {tx_frame_seq, tx_frame_crc, tx_frame_data};
    assign credit_s_valid = tx_frame_valid && active;
    assign tx_frame_ready = credit_s_ready && active;
    assign credit_m_ready = phy_ready_i && rx_ready && active;
    // Error injection is a digital verification hook placed at the abstract
    // channel boundary; it does not model an electrical fault mechanism.
    assign rx_frame_crc = credit_m_data[DATA_WIDTH+15:DATA_WIDTH] ^
                          (corrupt_crc_i ? 16'h0001 : 16'h0000);

    link_manager link_ctl (
        .clk(clk),
        .rst_n(rst_n),
        .start(link_start_i),
        .training_done(training_done_i),
        .fault(fault_i),
        .recovery_done(recovery_done_i),
        .link_up(link_manager_up),
        .state(link_state_o)
    );

    // Separate protocol-side queue from the replay register so one next word
    // can be buffered while the current word waits for ACK/retry completion.
    elastic_buffer #(.WIDTH(DATA_WIDTH)) ingress (
        .clk(clk),
        .rst_n(rst_n),
        .s_data(s_data_i),
        .s_valid(s_valid_i && active),
        .s_ready(ingress_ready),
        .m_data(ingress_data),
        .m_valid(ingress_valid),
        .m_ready(replay_s_ready && active)
    );

    generic_replay_tx #(
        .DATA_WIDTH(DATA_WIDTH),
        .MAX_RETRIES(MAX_RETRIES)
    ) tx_replay (
        .clk(clk),
        .rst_n(rst_n),
        .link_active_i(active),
        .s_data_i(ingress_data),
        .s_valid_i(ingress_valid && active),
        .s_ready_o(replay_s_ready),
        .frame_data_o(tx_frame_data),
        .frame_crc_o(tx_frame_crc),
        .frame_seq_o(tx_frame_seq),
        .frame_valid_o(tx_frame_valid),
        .frame_ready_i(tx_frame_ready),
        .response_valid_i(rx_response_valid),
        .response_ready_o(tx_response_ready),
        .response_ack_i(rx_response_ack),
        .response_seq_i(rx_response_seq),
        .busy_o(replay_busy),
        .failed_o(retry_failed_o),
        .retry_count_o(retry_count_o)
    );

    credit_tx #(
        .WIDTH(FRAME_WIDTH),
        .CREDIT_WIDTH(CREDIT_WIDTH)
    ) flow_control (
        .clk(clk),
        .rst_n(rst_n),
        .s_data(credit_s_data),
        .s_valid(credit_s_valid),
        .s_ready(credit_s_ready),
        .m_data(credit_m_data),
        .m_valid(credit_m_valid),
        .m_ready(credit_m_ready),
        .credit_return(credit_return_i && active),
        .credits(credits_o)
    );

    generic_crc_rx #(.DATA_WIDTH(DATA_WIDTH)) rx_integrity (
        .clk(clk),
        .rst_n(rst_n),
        .link_active_i(active),
        .frame_data_i(credit_m_data[DATA_WIDTH-1:0]),
        .frame_crc_i(rx_frame_crc),
        .frame_seq_i(credit_m_data[DATA_WIDTH+16]),
        // The digital PHY boundary may hold the beat; do not let the internal
        // receive checker observe it until that abstract channel is ready.
        .frame_valid_i(credit_m_valid && phy_ready_i),
        .frame_ready_o(rx_ready),
        .m_data_o(rx_data),
        .m_valid_o(rx_valid),
        .m_ready_i(m_ready_i),
        .response_valid_o(rx_response_valid),
        .response_ready_i(tx_response_ready),
        .response_ack_o(rx_response_ack),
        .response_seq_o(rx_response_seq),
        .crc_error_o(crc_error)
    );

    assign crc_error_o = crc_error;
    assign m_data_o = rx_data;
    assign m_valid_o = rx_valid;
endmodule
