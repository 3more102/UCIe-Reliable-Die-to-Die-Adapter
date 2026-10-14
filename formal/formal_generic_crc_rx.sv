// Bounded reference check for project-local CRC, ACK/NACK, duplicate, and hold behavior.
// This harness does not encode or assert UCIe receiver semantics.
module formal_generic_crc_rx;
    localparam integer DATA_WIDTH = 8;
    (* gclk *) reg clk;
    initial clk = 0;
    always @($global_clock) clk <= !clk;

    (* anyseq *) reg rst_n;
    (* anyseq *) reg link_active;
    (* anyseq *) reg [DATA_WIDTH-1:0] frame_data;
    (* anyseq *) reg [15:0] frame_crc;
    (* anyseq *) reg frame_seq;
    (* anyseq *) reg frame_valid;
    (* anyseq *) reg m_ready;
    (* anyseq *) reg response_ready;

    wire frame_ready;
    wire [DATA_WIDTH-1:0] m_data;
    wire m_valid;
    wire response_valid;
    wire response_ack;
    wire response_seq;
    wire crc_error;

    generic_crc_rx #(.DATA_WIDTH(DATA_WIDTH)) dut (
        .clk(clk), .rst_n(rst_n), .link_active_i(link_active),
        .frame_data_i(frame_data), .frame_crc_i(frame_crc),
        .frame_seq_i(frame_seq), .frame_valid_i(frame_valid),
        .frame_ready_o(frame_ready), .m_data_o(m_data), .m_valid_o(m_valid),
        .m_ready_i(m_ready), .response_valid_o(response_valid),
        .response_ready_i(response_ready), .response_ack_o(response_ack),
        .response_seq_o(response_seq), .crc_error_o(crc_error)
    );

    reg [DATA_WIDTH-1:0] ref_data = 0;
    reg ref_data_valid = 0;
    reg ref_expected_seq = 0;
    reg ref_response_valid = 0;
    reg ref_response_ack = 0;
    reg ref_response_seq = 0;
    reg ref_crc_error = 0;

    wire [DATA_WIDTH:0] ref_crc_input = {frame_seq, frame_data};
    wire [15:0] ref_calculated_crc;
    crc16_ccitt #(.DATA_WIDTH(DATA_WIDTH+1)) ref_crc_calc (
        .data_i(ref_crc_input), .crc_o(ref_calculated_crc)
    );
    wire ref_crc_good = (ref_calculated_crc == frame_crc);
    wire ref_duplicate = (frame_seq != ref_expected_seq);
    wire ref_can_accept = !ref_crc_good || ref_duplicate ||
                          !ref_data_valid || m_ready;
    wire ref_frame_ready = link_active && !ref_response_valid && ref_can_accept;
    wire ref_frame_handshake = frame_valid && ref_frame_ready;

    always @(posedge clk) begin
        if (!rst_n) begin
            ref_data <= 0;
            ref_data_valid <= 0;
            ref_expected_seq <= 0;
            ref_response_valid <= 0;
            ref_response_ack <= 0;
            ref_response_seq <= 0;
            ref_crc_error <= 0;
        end else begin
            assert(frame_ready == ref_frame_ready);
            assert(m_data == ref_data);
            assert(m_valid == ref_data_valid);
            assert(response_valid == (ref_response_valid && link_active));
            assert(response_ack == ref_response_ack);
            assert(response_seq == ref_response_seq);
            assert(crc_error == ref_crc_error);

            ref_crc_error <= 0;
            if (ref_data_valid && m_ready)
                ref_data_valid <= 0;
            if (ref_response_valid && response_ready && link_active)
                ref_response_valid <= 0;
            if (ref_frame_handshake) begin
                ref_response_valid <= 1;
                ref_response_seq <= frame_seq;
                ref_response_ack <= ref_crc_good;
                if (!ref_crc_good)
                    ref_crc_error <= 1;
                else if (!ref_duplicate) begin
                    ref_data <= frame_data;
                    ref_data_valid <= 1;
                    ref_expected_seq <= ~ref_expected_seq;
                end
            end
        end
    end
endmodule
