`timescale 1ns/1ps

module KernelBuffer3x3_TB;

    localparam WIDTH        = 8;
    localparam BUFFER_DEPTH = 8;
    localparam BUFFER_WIDTH = 16;

    // UUT inputs
    reg r_aclk = 1'b0;
    reg r_aresetn = 1'b1;
    reg r_tvalid = 1'b0;
    reg [WIDTH-1:0] r_tdata = 0;
    reg [$clog2(BUFFER_DEPTH)-1:0] r_sel = 0;
    
    // UUT outputs
    wire w_tready;
    wire w_buf_valid;

    wire [BUFFER_WIDTH-1:0] w_buf_00;
    wire [BUFFER_WIDTH-1:0] w_buf_01;
    wire [BUFFER_WIDTH-1:0] w_buf_02;

    wire [BUFFER_WIDTH-1:0] w_buf_10;
    wire [BUFFER_WIDTH-1:0] w_buf_11;
    wire [BUFFER_WIDTH-1:0] w_buf_12;

    wire [BUFFER_WIDTH-1:0] w_buf_20;
    wire [BUFFER_WIDTH-1:0] w_buf_21;
    wire [BUFFER_WIDTH-1:0] w_buf_22;


    KernelBuffer3x3 #(
        .WIDTH(WIDTH),
        .BUFFER_WIDTH(BUFFER_WIDTH), 
        .BUFFER_DEPTH(BUFFER_DEPTH)) UUT 
    (
        .i_aclk(r_aclk),
        .i_aresetn(r_aresetn),
        .i_tvalid(r_tvalid),
        .o_tready(w_tready),
        .i_tdata(r_tdata),

        .i_sel(r_sel),
        .o_buf_valid(w_buf_valid),

        .o_buf_00(w_buf_00),
        .o_buf_01(w_buf_01),
        .o_buf_02(w_buf_02),

        .o_buf_10(w_buf_10),
        .o_buf_11(w_buf_11),
        .o_buf_12(w_buf_12),

        .o_buf_20(w_buf_20),
        .o_buf_21(w_buf_21),
        .o_buf_22(w_buf_22)
    );

    // 50mhz clock
    always #20 r_aclk <= !r_aclk;

    task reset();
        @(posedge r_aclk);
        r_aresetn <= 1'b0;
        @(posedge r_aclk);
        r_aresetn <= 1'b1;
        @(posedge r_aclk);
        @(posedge r_aclk);
    endtask

    initial begin
        // reset buffer
        reset();

        repeat(BUFFER_WIDTH/WIDTH*9*BUFFER_DEPTH) begin
            r_tvalid <= 1'b1;
            @(posedge r_aclk);
            if (w_tready) begin
                r_tvalid <= 1'b0;
                r_tdata <= r_tdata + 1;
            end
        end

        repeat(BUFFER_DEPTH) begin
            @(posedge r_aclk);
            r_sel <= r_sel + 1;
        end
        @(posedge r_aclk);

        $finish();
    end

endmodule