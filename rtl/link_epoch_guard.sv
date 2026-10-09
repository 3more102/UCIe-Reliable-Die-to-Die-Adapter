// Generic link integrity primitive, NOT a UCIe protocol implementation.
// A transfer is accepted only while link_up is asserted. A link-down
// event flushes pending output; recovery cannot replay stale payloads.
module link_epoch_guard #(
    parameter integer WIDTH = 64
) (
    input wire clk,
    input wire rst_n,
    input wire link_up,
    input wire [WIDTH-1:0] s_data,
    input wire s_valid,
    output wire s_ready,
    output wire [WIDTH-1:0] m_data,
    output wire m_valid,
    input wire m_ready
);
    reg [WIDTH-1:0] data_q;
    reg full_q;
    assign s_ready = rst_n && link_up && (!full_q || m_ready);
    assign m_valid = rst_n && link_up && full_q;
    assign m_data = data_q;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            full_q <= 1'b0;
            data_q <= {WIDTH{1'b0}};
        end else if (!link_up) begin
            full_q <= 1'b0;
            data_q <= {WIDTH{1'b0}};
        end else if (s_ready) begin
            full_q <= s_valid;
            if (s_valid)
                data_q <= s_data;
        end
    end
endmodule
