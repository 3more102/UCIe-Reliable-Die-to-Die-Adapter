module tb_crc16_guard;
    reg [71:0] data;
    reg [15:0] received_crc;
    wire [15:0] computed_crc;
    wire crc_ok;
    crc16_guard #(.DATA_WIDTH(72)) dut (
        .data(data), .received_crc(received_crc),
        .computed_crc(computed_crc), .crc_ok(crc_ok));
    initial begin
        data = 72'h313233343536373839;
        received_crc = 16'h29B1;
        #1;
        if (!crc_ok || computed_crc !== 16'h29B1)
            $fatal(1,"valid word rejected");
        data[0] = ~data[0];
        #1;
        if (crc_ok || computed_crc === 16'h29B1)
            $fatal(1,"single-bit corruption not detected");
        data[0] = ~data[0];
        received_crc = 16'h29B0;
        #1;
        if (crc_ok) $fatal(1,"corrupt CRC accepted");
        $display("PASS CRC guard corruption checks");
        $finish;
    end
endmodule
