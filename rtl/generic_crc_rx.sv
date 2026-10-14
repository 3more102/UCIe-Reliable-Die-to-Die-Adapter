// Project-defined one-entry CRC checker and duplicate suppressor.
// The CRC, sequence convention and ACK/NACK behavior are local verification
// choices and are not asserted to match UCIe normative behavior.
module generic_crc_rx #(
    parameter integer DATA_WIDTH = 64
) (
    input  wire                  clk,
    input  wire                  rst_n,
    input  wire                  link_active_i,
    input  wire [DATA_WIDTH-1:0] frame_data_i,
    input  wire [15:0]           frame_crc_i,
    input  wire                  frame_seq_i,
    input  wire                  frame_valid_i,
    output wire                  frame_ready_o,
    output wire [DATA_WIDTH-1:0] m_data_o,
    output wire                  m_valid_o,
    input  wire                  m_ready_i,
    output wire                  response_valid_o,
    input  wire                  response_ready_i,
    output wire                  response_ack_o,
    output wire                  response_seq_o,
    output reg                   crc_error_o
);
    reg [DATA_WIDTH-1:0] data_q;
    reg data_valid_q;
    reg expected_seq_q;
    reg response_valid_q;
    reg response_ack_q;
    reg response_seq_q;
    wire [DATA_WIDTH:0] crc_input;
    wire [15:0] calculated_crc;
    wire crc_good;
    wire duplicate_frame;
    wire can_accept_frame;
    wire frame_handshake;
    wire data_pop;
    wire response_pop;

    assign crc_input = {frame_seq_i, frame_data_i};
    crc16_ccitt #(.DATA_WIDTH(DATA_WIDTH + 1)) crc_calc (
        .data_i(crc_input),
        .crc_o(calculated_crc)
    );
    assign crc_good = (calculated_crc == frame_crc_i);
    assign duplicate_frame = (frame_seq_i != expected_seq_q);
    assign can_accept_frame = !crc_good || duplicate_frame || !data_valid_q || m_ready_i;
    assign frame_ready_o = link_active_i && !response_valid_q && can_accept_frame;
    assign frame_handshake = frame_valid_i && frame_ready_o;
    assign data_pop = data_valid_q && m_ready_i;
    assign response_pop = response_valid_q && response_ready_i && link_active_i;

    assign m_data_o = data_q;
    assign m_valid_o = data_valid_q;
    assign response_valid_o = response_valid_q && link_active_i;
    assign response_ack_o = response_ack_q;
    assign response_seq_o = response_seq_q;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            data_q <= {DATA_WIDTH{1'b0}};
            data_valid_q <= 1'b0;
            expected_seq_q <= 1'b0;
            response_valid_q <= 1'b0;
            response_ack_q <= 1'b0;
            response_seq_q <= 1'b0;
            crc_error_o <= 1'b0;
        end else begin
            crc_error_o <= 1'b0;

            if (data_pop)
                data_valid_q <= 1'b0;
            if (response_pop)
                response_valid_q <= 1'b0;

            if (frame_handshake) begin
                response_valid_q <= 1'b1;
                response_seq_q <= frame_seq_i;
                response_ack_q <= crc_good;
                if (!crc_good) begin
                    crc_error_o <= 1'b1;
                end else if (!duplicate_frame) begin
                    data_q <= frame_data_i;
                    data_valid_q <= 1'b1;
                    expected_seq_q <= ~expected_seq_q;
                end
            end
        end
    end
endmodule
