// Prototype link controller. States are project-local, NOT normative UCIe states.
module link_manager (
    input wire clk,
    input wire rst_n,
    input wire start,
    input wire training_done,
    input wire fault,
    input wire recovery_done,
    output wire link_up,
    output reg [1:0] state
);
    localparam [1:0] DOWN=2'd0, TRAINING=2'd1, ACTIVE=2'd2, RECOVERY=2'd3;
    assign link_up = (state == ACTIVE);
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) state <= DOWN;
        else case (state)
            DOWN: if (start) state <= TRAINING;
            TRAINING: if (fault) state <= RECOVERY;
                      else if (training_done) state <= ACTIVE;
            ACTIVE: if (fault) state <= RECOVERY;
            RECOVERY: if (recovery_done && !fault) state <= TRAINING;
            default: state <= DOWN;
        endcase
    end
endmodule
