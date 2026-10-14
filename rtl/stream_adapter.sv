// Generic single-clock streaming integration demonstrator.
// This is NOT a UCIe adapter: no UCIe flit framing, CRC, replay or PHY.
module stream_adapter #(
    parameter integer WIDTH=64,
    parameter integer CREDIT_WIDTH=8,
    // Compile-time digital profile selection. This does not model a PHY clock.
    parameter integer RATE_PROFILE_GT_S=64
) (
    input wire clk,
    input wire rst_n,
    input wire link_up,
    input wire [WIDTH-1:0] s_data,
    input wire s_valid,
    output wire s_ready,
    output wire [WIDTH-1:0] m_data,
    output wire m_valid,
    input wire m_ready,
    input wire credit_return,
    output wire [CREDIT_WIDTH-1:0] credits,
    output wire rate_profile_supported,
    output wire [6:0] configured_rate_gt_s
);
    localparam integer RATE_PROFILE_SUPPORTED =
        (RATE_PROFILE_GT_S == 48) || (RATE_PROFILE_GT_S == 64);
    wire active_link;
    wire [WIDTH-1:0] buffered_data;
    wire buffered_valid, buffered_ready;
    wire tx_ready;
    wire ingress_ready;

    // The public UCIe 3.0 overview lists 48 and 64 GT/s. This integer selects
    // only a digital profile label; it is not a serial-rate or PHY model.
    assign rate_profile_supported = RATE_PROFILE_SUPPORTED;
    assign configured_rate_gt_s = RATE_PROFILE_SUPPORTED ? RATE_PROFILE_GT_S : 7'd0;
    assign active_link = link_up && rate_profile_supported;

    elastic_buffer #(.WIDTH(WIDTH)) ingress (
        .clk(clk),.rst_n(rst_n),.s_data(s_data),
        .s_valid(s_valid && active_link),.s_ready(ingress_ready),
        .m_data(buffered_data),.m_valid(buffered_valid),
        .m_ready(buffered_ready));
    assign s_ready = active_link && ingress_ready;

    // Do not consume pending data when the link is down or configuration is
    // unsupported. This preserves the buffered word for link recovery.
    assign buffered_ready = active_link && tx_ready;
    credit_tx #(.WIDTH(WIDTH),.CREDIT_WIDTH(CREDIT_WIDTH)) tx (
        .clk(clk),.rst_n(rst_n),.s_data(buffered_data),
        .s_valid(buffered_valid && active_link),.s_ready(tx_ready),
        .m_data(m_data),.m_valid(m_valid),.m_ready(m_ready),
        .credit_return(credit_return),.credits(credits));
endmodule
