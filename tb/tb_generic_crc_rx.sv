module tb_generic_crc_rx;
    reg clk = 0;
    always #5 clk = ~clk;
    reg rst_n = 0;
    reg link_active = 0;
    reg [7:0] frame_data = 0;
    reg [15:0] frame_crc = 0;
    reg frame_seq = 0;
    reg frame_valid = 0;
    wire frame_ready;
    wire [7:0] m_data;
    wire m_valid;
    reg m_ready = 0;
    wire response_valid;
    reg response_ready = 0;
    wire response_ack;
    wire response_seq;
    wire crc_error;
    reg [8:0] crc_input = 0;
    wire [15:0] calculated_crc;
    integer timeout;

    crc16_ccitt #(.DATA_WIDTH(9)) crc_calc (
        .data_i(crc_input), .crc_o(calculated_crc)
    );
    generic_crc_rx #(.DATA_WIDTH(8)) dut (
        .clk(clk), .rst_n(rst_n), .link_active_i(link_active),
        .frame_data_i(frame_data), .frame_crc_i(frame_crc),
        .frame_seq_i(frame_seq), .frame_valid_i(frame_valid),
        .frame_ready_o(frame_ready), .m_data_o(m_data), .m_valid_o(m_valid),
        .m_ready_i(m_ready), .response_valid_o(response_valid),
        .response_ready_i(response_ready), .response_ack_o(response_ack),
        .response_seq_o(response_seq), .crc_error_o(crc_error)
    );

    task send_frame(input bit seq, input [7:0] data_value, input bit corrupt);
        begin
            crc_input = {seq, data_value};
            #1;
            @(negedge clk);
            frame_seq = seq;
            frame_data = data_value;
            frame_crc = calculated_crc ^ (corrupt ? 16'h0001 : 16'h0000);
            frame_valid = 1;
            timeout = 0;
            while (!frame_ready && timeout < 20) begin
                @(negedge clk);
                timeout = timeout + 1;
            end
            if (!frame_ready) $fatal(1, "timed out waiting for receiver capacity");
            @(negedge clk);
            frame_valid = 0;
        end
    endtask

    task consume_response(input bit expected_ack, input bit expected_seq);
        begin
            timeout = 0;
            while (!response_valid && timeout < 20) begin
                @(negedge clk);
                timeout = timeout + 1;
            end
            if (!response_valid) $fatal(1, "timed out waiting for response");
            if (response_ack !== expected_ack || response_seq !== expected_seq)
                $fatal(1, "response mismatch ack=%b seq=%b", response_ack, response_seq);
            response_ready = 1;
            @(negedge clk);
            response_ready = 0;
        end
    endtask

    initial begin
        repeat (2) @(negedge clk);
        rst_n = 1;
        link_active = 1;

        send_frame(1'b0, 8'hA6, 1'b0);
        link_active = 0;
        repeat (2) begin
            @(negedge clk);
            if (response_valid || !m_valid || m_data !== 8'hA6)
                $fatal(1, "receiver response/data retention across link loss failed");
        end
        link_active = 1;
        consume_response(1'b1, 1'b0);
        if (!m_valid || m_data !== 8'hA6)
            $fatal(1, "new frame was not delivered");

        // A repeated valid sequence is ACKed but not delivered a second time.
        send_frame(1'b0, 8'hA6, 1'b0);
        consume_response(1'b1, 1'b0);
        if (!m_valid || m_data !== 8'hA6 || crc_error)
            $fatal(1, "duplicate frame changed buffered data or raised CRC error");
        m_ready = 1;
        @(negedge clk);
        m_ready = 0;
        if (m_valid) $fatal(1, "receive buffer did not pop accepted data");
        repeat (2) begin
            @(negedge clk);
            if (m_valid) $fatal(1, "duplicate frame was delivered twice");
        end

        // The next expected sequence still advances normally after suppression.
        send_frame(1'b1, 8'h5C, 1'b0);
        consume_response(1'b1, 1'b1);
        if (!m_valid || m_data !== 8'h5C)
            $fatal(1, "next in-order frame was not delivered");

        $display("PASS tb_generic_crc_rx duplicate suppression");
        $finish;
    end
endmodule
