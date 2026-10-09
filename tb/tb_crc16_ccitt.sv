module tb_crc16_ccitt;
    reg [71:0] data;
    wire [15:0] crc;
    crc16_ccitt #(.DATA_WIDTH(72)) dut(.data(data),.crc(crc));
    initial begin
        // Published CRC-16/CCITT-FALSE check vector:
        // ASCII "123456789" => 0x29B1.
        data = 72'h313233343536373839;
        #1;
        if (crc !== 16'h29B1)
            $fatal(1,"CRC check vector mismatch: got %04h",crc);
        $display("PASS CRC-16/CCITT-FALSE check vector");
        $finish;
    end
endmodule
