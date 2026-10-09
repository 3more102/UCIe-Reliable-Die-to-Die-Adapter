// Generic single-clock streaming integration demonstrator.
// This is NOT a UCIe adapter: no UCIe flit framing, CRC, replay or PHY.
module stream_adapter #(
    parameter integer WIDTH=64,
    parameter integer CREDIT_WIDTH=8
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
    output wire [CREDIT_WIDTH-1:0] credits
);
    wire [WIDTH-1:0] buffered_data;
    wire buffered_valid, buffered_ready, tx_ready;
    // Keep a buffered beat while the link is down. The generic credit gate
    // does not know link_up and can otherwise consume it without transmitting.
    assign buffered_ready = link_up && tx_ready;
    wire ingress_ready;
    elastic_buffer #(.WIDTH(WIDTH)) ingress (
        .clk(clk),.rst_n(rst_n),.s_data(s_data),
        .s_valid(s_valid && link_up),.s_ready(ingress_ready),
        .m_data(buffered_data),.m_valid(buffered_valid),
        .m_ready(buffered_ready));
    assign s_ready = link_up && ingress_ready;
    credit_tx #(.WIDTH(WIDTH),.CREDIT_WIDTH(CREDIT_WIDTH)) tx (
        .clk(clk),.rst_n(rst_n),.s_data(buffered_data),
        .s_valid(buffered_valid && link_up),.s_ready(tx_ready),
        .m_data(m_data),.m_valid(m_valid),.m_ready(m_ready),
        .credit_return(credit_return),.credits(credits));
endmodule
