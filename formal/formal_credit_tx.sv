// Independent bounded-credit reference for the project's generic credit TX.
// The accounting rules here are project-defined, not UCIe normative behavior.
module formal_credit_tx;
    localparam integer WIDTH = 32;
    localparam integer CREDIT_WIDTH = 4;
    localparam [CREDIT_WIDTH-1:0] MAX_CREDITS = {CREDIT_WIDTH{1'b1}};
    (* gclk *) reg clk;
    initial clk = 0;
    always @($global_clock) clk <= !clk;

    (* anyseq *) reg rst_n;
    (* anyseq *) reg [WIDTH-1:0] s_data;
    (* anyseq *) reg s_valid;
    (* anyseq *) reg m_ready;
    (* anyseq *) reg credit_return;
    wire s_ready;
    wire [WIDTH-1:0] m_data;
    wire m_valid;
    wire [CREDIT_WIDTH-1:0] credits;

    credit_tx #(.WIDTH(WIDTH), .CREDIT_WIDTH(CREDIT_WIDTH)) dut (
        .clk(clk), .rst_n(rst_n), .s_data(s_data), .s_valid(s_valid),
        .s_ready(s_ready), .m_data(m_data), .m_valid(m_valid),
        .m_ready(m_ready), .credit_return(credit_return), .credits(credits)
    );

    reg [CREDIT_WIDTH-1:0] ref_credits = 0;
    wire ref_send = s_valid && m_ready && (ref_credits != 0);
    always @(posedge clk) begin
        if (!rst_n) begin
            ref_credits <= 0;
        end else begin
            assert(credits == ref_credits);
            assert(m_valid == (s_valid && (ref_credits != 0)));
            assert(s_ready == (m_ready && (ref_credits != 0)));
            assert(m_data == s_data);
            case ({credit_return, ref_send})
                2'b10: if (ref_credits != MAX_CREDITS)
                    ref_credits <= ref_credits + 1'b1;
                2'b01: ref_credits <= ref_credits - 1'b1;
                default: ref_credits <= ref_credits;
            endcase
        end
    end
endmodule
