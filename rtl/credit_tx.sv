// Generic credit-gated ready/valid transmitter.
// NOT UCIe normative credit behavior. Credit increments are bounded and
// credits are consumed only on a completed output handshake.
module credit_tx #(
    parameter integer WIDTH = 64,
    parameter integer CREDIT_WIDTH = 8
) (
    input wire clk,
    input wire rst_n,
    input wire [WIDTH-1:0] s_data,
    input wire s_valid,
    output wire s_ready,
    output wire [WIDTH-1:0] m_data,
    output wire m_valid,
    input wire m_ready,
    input wire credit_return,
    output reg [CREDIT_WIDTH-1:0] credits
);
    wire send;
    assign m_data = s_data;
    assign m_valid = s_valid && (credits != 0);
    assign s_ready = m_ready && (credits != 0);
    assign send = m_valid && m_ready;
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            credits <= {CREDIT_WIDTH{1'b0}};
        else
            case ({credit_return,send})
                2'b10: if (&credits == 1'b0) credits <= credits + 1'b1;
                2'b01: credits <= credits - 1'b1;
                default: credits <= credits;
            endcase
    end
endmodule
