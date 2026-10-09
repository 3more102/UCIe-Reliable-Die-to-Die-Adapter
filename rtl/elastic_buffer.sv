// Generic ready/valid elastic buffer. Infrastructure only; not a UCIe protocol block.
module elastic_buffer #(
    parameter integer WIDTH = 64
) (
    input  wire             clk,
    input  wire             rst_n,
    input  wire [WIDTH-1:0] s_data,
    input  wire             s_valid,
    output wire             s_ready,
    output wire [WIDTH-1:0] m_data,
    output wire             m_valid,
    input  wire             m_ready
);
    reg [WIDTH-1:0] data_q;
    reg full_q;

    assign s_ready = !full_q || m_ready;
    assign m_valid = full_q;
    assign m_data  = data_q;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            full_q <= 1'b0;
            data_q <= {WIDTH{1'b0}};
        end else if (s_ready) begin
            full_q <= s_valid;
            if (s_valid)
                data_q <= s_data;
        end
    end
endmodule
