// Project-defined stop-and-wait replay sender for digital verification.
// The one-bit sequence tag, response protocol and retry limit are local
// choices; this module does not implement normative UCIe retry behavior.
module generic_replay_tx #(
    parameter integer DATA_WIDTH = 64,
    parameter integer MAX_RETRIES = 2,
    parameter integer RETRY_COUNT_WIDTH = 8,
    // Project-local model cycles; zero disables response timeout.
    parameter integer RESPONSE_TIMEOUT_CYCLES = 16
) (
    input  wire                         clk,
    input  wire                         rst_n,
    input  wire                         link_active_i,
    input  wire [DATA_WIDTH-1:0]        s_data_i,
    input  wire                         s_valid_i,
    output wire                         s_ready_o,
    output wire [DATA_WIDTH-1:0]        frame_data_o,
    output wire [15:0]                  frame_crc_o,
    output wire                         frame_seq_o,
    output wire                         frame_valid_o,
    input  wire                         frame_ready_i,
    input  wire                         response_valid_i,
    output wire                         response_ready_o,
    input  wire                         response_ack_i,
    input  wire                         response_seq_i,
    output wire                         busy_o,
    output wire                         failed_o,
    output reg  [RETRY_COUNT_WIDTH-1:0] retry_count_o
);
    localparam [1:0] IDLE = 2'd0;
    localparam [1:0] SEND = 2'd1;
    localparam [1:0] WAIT_RESPONSE = 2'd2;
    localparam [1:0] FAILED = 2'd3;

    reg [1:0] state_q;
    reg [DATA_WIDTH-1:0] data_q;
    reg [15:0] crc_q;
    reg seq_q;
    reg next_seq_q;
    localparam integer TIMER_WIDTH = (RESPONSE_TIMEOUT_CYCLES > 1) ?
                                     $clog2(RESPONSE_TIMEOUT_CYCLES) : 1;
    reg [TIMER_WIDTH-1:0] response_wait_q;
    wire [DATA_WIDTH:0] crc_input;
    wire [15:0] calculated_crc;
    wire frame_handshake;
    wire response_handshake;

    assign crc_input = {seq_q, s_data_i};
    crc16_ccitt #(.DATA_WIDTH(DATA_WIDTH + 1)) crc_calc (
        .data_i(crc_input),
        .crc_o(calculated_crc)
    );

    assign s_ready_o = (state_q == IDLE) && link_active_i;
    assign frame_data_o = data_q;
    assign frame_crc_o = crc_q;
    assign frame_seq_o = seq_q;
    assign frame_valid_o = (state_q == SEND) && link_active_i;
    assign response_ready_o = (state_q == WAIT_RESPONSE) && link_active_i;
    assign busy_o = (state_q != IDLE) && (state_q != FAILED);
    assign failed_o = (state_q == FAILED);
    assign frame_handshake = frame_valid_o && frame_ready_i;
    assign response_handshake = response_valid_i && response_ready_o;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state_q <= IDLE;
            data_q <= {DATA_WIDTH{1'b0}};
            crc_q <= 16'h0000;
            seq_q <= 1'b0;
            retry_count_o <= {RETRY_COUNT_WIDTH{1'b0}};
            response_wait_q <= {TIMER_WIDTH{1'b0}};
        end else begin
            case (state_q)
                IDLE: begin
                    if (s_valid_i && s_ready_o) begin
                        data_q <= s_data_i;
                        crc_q <= calculated_crc;
                        retry_count_o <= {RETRY_COUNT_WIDTH{1'b0}};
                        response_wait_q <= {TIMER_WIDTH{1'b0}};
                        state_q <= SEND;
                    end
                end
                SEND: begin
                    if (frame_handshake) begin
                        response_wait_q <= {TIMER_WIDTH{1'b0}};
                        state_q <= WAIT_RESPONSE;
                    end
                end
                WAIT_RESPONSE: begin
                    if (response_handshake && response_seq_i == seq_q) begin
                        response_wait_q <= {TIMER_WIDTH{1'b0}};
                        if (response_ack_i) begin
                            seq_q <= ~seq_q;
                            state_q <= IDLE;
                        end else if (retry_count_o < MAX_RETRIES) begin
                            retry_count_o <= retry_count_o + 1'b1;
                            state_q <= SEND;
                        end else begin
                            state_q <= FAILED;
                        end
                    end else if (RESPONSE_TIMEOUT_CYCLES > 0 && link_active_i) begin
                        // A matching response wins if it arrives on the expiry
                        // edge. Time advances only on active-link model cycles.
                        if (response_wait_q == RESPONSE_TIMEOUT_CYCLES - 1) begin
                            response_wait_q <= {TIMER_WIDTH{1'b0}};
                            if (retry_count_o < MAX_RETRIES) begin
                                retry_count_o <= retry_count_o + 1'b1;
                                state_q <= SEND;
                            end else begin
                                state_q <= FAILED;
                            end
                        end else begin
                            response_wait_q <= response_wait_q + 1'b1;
                        end
                    end
                end
                FAILED: state_q <= FAILED;
                default: state_q <= IDLE;
            endcase
        end
    end
endmodule
