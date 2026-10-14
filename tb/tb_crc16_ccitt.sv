module tb_crc16_ccitt;
    reg [71:0] data;
    wire [15:0] crc;

    crc16_ccitt #(.DATA_WIDTH(72)) dut (
        .data_i(data),
        .crc_o(crc)
    );

    initial begin
        data = 72'h313233343536373839; // ASCII "123456789"
        #1;
        if (crc !== 16'h29B1)
            $fatal(1, "CRC known answer mismatch: got %04x expected 29b1", crc);
        data = data ^ 72'h000000000000000001;
        #1;
        if (crc === 16'h29B1)
            $fatal(1, "single-bit corruption did not change CRC");
        $display("PASS tb_crc16_ccitt");
        $finish;
    end
endmodule
