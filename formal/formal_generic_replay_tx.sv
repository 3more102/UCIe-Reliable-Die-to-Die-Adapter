// Reference-checks the project-defined stop-and-wait replay sender state machine.
// Sequence width, CRC coverage, response semantics, and retry limit are local.
module formal_generic_replay_tx;
    localparam integer DATA_WIDTH = 8;
    localparam integer MAX_RETRIES = 2;
    localparam [1:0] IDLE = 2'd0, SEND = 2'd1, WAIT_RESPONSE = 2'd2, FAILED = 2'd3;

    (* gclk *) reg clk;
    initial clk = 0;
    always @($global_clock) clk <= !clk;

    (* anyseq *) reg rst_n;
    (* anyseq *) reg link_active;
    (* anyseq *) reg [DATA_WIDTH-1:0] s_data;
    (* anyseq *) reg s_valid;
    (* anyseq *) reg frame_ready;
    (* anyseq *) reg response_valid;
    (* anyseq *) reg response_ack;
    (* anyseq *) reg response_seq;

    wire s_ready;
    wire [DATA_WIDTH-1:0] frame_data;
    wire [15:0] frame_crc;
    wire frame_seq;
    wire frame_valid;
    wire response_ready;
    wire busy;
    wire failed;
    wire [7:0] retry_count;

    generic_replay_tx #(.DATA_WIDTH(DATA_WIDTH), .MAX_RETRIES(MAX_RETRIES)) dut (
        .clk(clk), .rst_n(rst_n), .link_active_i(link_active),
        .s_data_i(s_data), .s_valid_i(s_valid), .s_ready_o(s_ready),
        .frame_data_o(frame_data), .frame_crc_o(frame_crc),
        .frame_seq_o(frame_seq), .frame_valid_o(frame_valid),
        .frame_ready_i(frame_ready), .response_valid_i(response_valid),
        .response_ready_o(response_ready), .response_ack_i(response_ack),
        .response_seq_i(response_seq), .busy_o(busy), .failed_o(failed),
        .retry_count_o(retry_count)
    );

    reg [1:0] ref_state = IDLE;
    reg [DATA_WIDTH-1:0] ref_data = 0;
    reg [15:0] ref_crc = 0;
    reg ref_seq = 0;
    reg [7:0] ref_retries = 0;
    wire [DATA_WIDTH:0] ref_crc_input = {ref_seq, s_data};
    wire [15:0] ref_calculated_crc;
    crc16_ccitt #(.DATA_WIDTH(DATA_WIDTH+1)) ref_crc_calc (
        .data_i(ref_crc_input), .crc_o(ref_calculated_crc)
    );

    always @(posedge clk) begin
        if (!rst_n) begin
            ref_state <= IDLE;
            ref_data <= 0;
            ref_crc <= 0;
            ref_seq <= 0;
            ref_retries <= 0;
        end else begin
            assert(s_ready == ((ref_state == IDLE) && link_active));
            assert(frame_valid == ((ref_state == SEND) && link_active));
            assert(frame_data == ref_data);
            assert(frame_crc == ref_crc);
            assert(frame_seq == ref_seq);
            assert(response_ready == ((ref_state == WAIT_RESPONSE) && link_active));
            assert(busy == ((ref_state != IDLE) && (ref_state != FAILED)));
            assert(failed == (ref_state == FAILED));
            assert(retry_count == ref_retries);

            case (ref_state)
                IDLE: if (s_valid && link_active) begin
                    ref_data <= s_data;
                    ref_crc <= ref_calculated_crc;
                    ref_retries <= 0;
                    ref_state <= SEND;
                end
                SEND: if (link_active && frame_ready)
                    ref_state <= WAIT_RESPONSE;
                WAIT_RESPONSE: if (link_active && response_valid &&
                                    response_seq == ref_seq) begin
                    if (response_ack) begin
                        ref_seq <= ~ref_seq;
                        ref_state <= IDLE;
                    end else if (ref_retries < MAX_RETRIES) begin
                        ref_retries <= ref_retries + 1'b1;
                        ref_state <= SEND;
                    end else begin
                        ref_state <= FAILED;
                    end
                end
                FAILED: ref_state <= FAILED;
                default: ref_state <= IDLE;
            endcase
        end
    end
endmodule
