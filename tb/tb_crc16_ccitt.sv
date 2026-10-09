// Directed checks for generic CRC-16/CCITT-FALSE implementation.
// Reference vector "123456789" => 16'h29B1 (MSB-first, init FFFF).
module tb_crc16_ccitt;
    reg [71:0] data_i;
    wire [15:0] crc_o;
    crc16_ccitt #(.DATA_WIDTH(72)) dut (
        .data_i(data_i), .crc_o(crc_o)
    );
    initial begin
        data_i = 72'h313233343536373839;
        #1;
        if (crc_o !== 16'h29B1)
            $fatal(1, "CRC reference mismatch: got %h expected 29B1", crc_o);
        data_i = 72'h000000000000000000;
        #1;
        if (^crc_o === 1'bx)
            $fatal(1, "CRC contains unknown bits");
        $display("PASS crc16_ccitt");
        $finish;
    end
endmodule
