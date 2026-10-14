// Reference-checks the prototype FSM transitions; state names/timing are local.
module formal_link_manager;
    localparam [1:0] DOWN=2'd0, TRAINING=2'd1, ACTIVE=2'd2, RECOVERY=2'd3;
    (* gclk *) reg clk;
    initial clk = 0;
    always @($global_clock) clk <= !clk;

    (* anyseq *) reg rst_n;
    (* anyseq *) reg start;
    (* anyseq *) reg training_done;
    (* anyseq *) reg fault;
    (* anyseq *) reg recovery_done;
    wire link_up;
    wire [1:0] state;

    link_manager dut (
        .clk(clk), .rst_n(rst_n), .start(start), .training_done(training_done),
        .fault(fault), .recovery_done(recovery_done), .link_up(link_up), .state(state)
    );

    reg [1:0] ref_state = DOWN;
    always @(posedge clk) begin
        if (!rst_n)
            ref_state <= DOWN;
        else begin
            assert(state == ref_state);
            assert(link_up == (ref_state == ACTIVE));
            case (ref_state)
                DOWN: if (start) ref_state <= TRAINING;
                TRAINING: if (fault) ref_state <= RECOVERY;
                           else if (training_done) ref_state <= ACTIVE;
                ACTIVE: if (fault) ref_state <= RECOVERY;
                RECOVERY: if (recovery_done && !fault) ref_state <= TRAINING;
                default: ref_state <= DOWN;
            endcase
        end
    end
endmodule
