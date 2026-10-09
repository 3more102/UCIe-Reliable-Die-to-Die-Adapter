module tb_link_manager;
    reg clk=0;
    always #5 clk=~clk;
    reg rst_n=0, start=0, training_done=0, fault=0, recovery_done=0;
    wire link_up;
    wire [1:0] state;
    link_manager dut(.*);
    initial begin
        repeat(2) @(negedge clk);
        if (state !== 0 || link_up) $fatal(1,"reset failed");
        rst_n=1; start=1;
        @(negedge clk);
        if (state !== 1 || link_up) $fatal(1,"training failed");
        start=0; training_done=1;
        @(negedge clk);
        if (state !== 2 || !link_up) $fatal(1,"active failed");
        training_done=0; fault=1;
        @(negedge clk);
        if (state !== 3 || link_up) $fatal(1,"recovery entry failed");
        fault=0; recovery_done=1;
        @(negedge clk);
        if (state !== 1 || link_up) $fatal(1,"recovery exit failed");
        $display("PASS link_manager");
        $finish;
    end
    initial begin #1000; $fatal(1,"timeout"); end
endmodule
