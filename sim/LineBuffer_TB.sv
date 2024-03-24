`timescale 1ns/1ps

module LineBuffer_TB;

    localparam WIDTH = 8;
    localparam DEPTH = 8;

    reg r_clk = 1'b0; 
    reg r_resetn = 1'b0;
    reg r_wr_valid = 1'b0;
    reg [WIDTH-1:0] r_wr_data = 0;

    wire w_rd_valid;
    wire [WIDTH-1:0] w_rd_data;

    LineBuffer #(.DEPTH(DEPTH), .WIDTH(WIDTH)) UUT 
    (
        .i_clk(r_clk), 
        .i_resetn(r_resetn), 
        .i_wr_valid(r_wr_valid),
        .i_wr_data(r_wr_data),
        .o_rd_valid(w_rd_valid),
        .o_rd_data(w_rd_data)
    );

    // 50mhz clock
    always #20 r_clk <= !r_clk;

    task reset();
        @(posedge r_clk);
        r_resetn <= 1'b0;
        @(posedge r_clk);
        r_resetn <= 1'b1;
        @(posedge r_clk);
        @(posedge r_clk);
    endtask

    initial begin
        // reset buffer
        reset();

        // buffer empty, assert invalid reads
        assert (!w_rd_valid);

        repeat(DEPTH) begin
            r_wr_valid <= 1'b1;
            @(posedge r_clk);
            r_wr_valid <= 1'b0;
            r_wr_data <= r_wr_data + 1;

            // buffer not full
            assert (!w_rd_valid);
        end

        // fill rest of buffer
        repeat(DEPTH*2) begin
            r_wr_valid <= 1'b1;
            @(posedge r_clk);
            r_wr_valid <= 1'b0;
            r_wr_data <= r_wr_data + 1;

            // buffer full, assert valid
            assert (w_rd_valid);
        end

        reset();
        assert (!w_rd_valid);

        $finish();
    end

endmodule