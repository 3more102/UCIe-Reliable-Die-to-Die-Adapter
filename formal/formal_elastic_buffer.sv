// Independent queue reference for the project's one-entry ready/valid buffer.
// Proves sampled-cycle data/valid equivalence; this is not a UCIe protocol proof.
module formal_elastic_buffer;
    localparam integer WIDTH = 32;
    (* gclk *) reg clk;
    initial clk = 0;
    always @($global_clock) clk <= !clk;

    (* anyseq *) reg rst_n;
    (* anyseq *) reg [WIDTH-1:0] s_data;
    (* anyseq *) reg s_valid;
    (* anyseq *) reg m_ready;
    wire s_ready;
    wire [WIDTH-1:0] m_data;
    wire m_valid;

    elastic_buffer #(.WIDTH(WIDTH)) dut (
        .clk(clk), .rst_n(rst_n), .s_data(s_data), .s_valid(s_valid),
        .s_ready(s_ready), .m_data(m_data), .m_valid(m_valid), .m_ready(m_ready)
    );

    reg ref_valid = 0;
    reg [WIDTH-1:0] ref_data = 0;
    always @(posedge clk) begin
        if (!rst_n) begin
            ref_valid <= 0;
            ref_data <= 0;
        end else begin
            assert(m_valid == ref_valid);
            if (ref_valid)
                assert(m_data == ref_data);
            if (ref_valid && m_ready)
                ref_valid <= 0;
            if (s_valid && s_ready) begin
                ref_valid <= 1;
                ref_data <= s_data;
            end
        end
    end
endmodule
