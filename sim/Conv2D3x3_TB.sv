`timescale 1ns/1ps

module Conv2D3x3_TB;

    localparam IN_HEIGHT    = 4;
    localparam IN_WIDTH     = 4;
    localparam IN_CHANNEL   = 2;
    localparam WIDTH        = 8;
    localparam WORD_WIDTH   = 8; 
    localparam FILTERS      = 8;
    localparam KERNEL_BUF_WIDTH = 64;

    localparam DEPTH        = IN_HEIGHT*IN_WIDTH*IN_CHANNEL + 8;
    localparam KERNEL_DEPTH = 3*3*FILTERS*IN_CHANNEL*WORD_WIDTH/KERNEL_BUF_WIDTH;

    reg r_aclk = 1'b0; 
    reg r_aresetn = 1'b0;
    reg r_tvalid = 1'b0;
    reg [WORD_WIDTH-1:0] r_tdata = 0;
    reg r_kernel_tvalid = 1'b0;
    reg [63:0] r_kernel_tdata = 64'h0101010101010101;

    wire w_tready;
    wire w_kernel_tready;
    wire w_tvalid;
    wire [WORD_WIDTH*8-1:0] w_tdata;

    Conv2D3x3 #(
        .IN_HEIGHT(IN_HEIGHT), 
        .IN_WIDTH(IN_WIDTH), 
        .IN_CHANNEL(IN_CHANNEL), 
        .WIDTH(WIDTH), 
        .WORD_WIDTH(WORD_WIDTH), 
        .FILTERS(FILTERS),
        .KERNEL_BUF_WIDTH(KERNEL_BUF_WIDTH)) UUT
        (
            .i_aclk(r_aclk),
            .i_aresetn(r_aresetn),
            .i_tvalid(r_tvalid),
            .o_tready(w_tready),
            .i_tdata(r_tdata),

            .i_kernel_tvalid(r_kernel_tvalid),
            .o_kernel_tready(w_kernel_tready),
            .i_kernel_tdata(r_kernel_tdata),

            .i_tready(1'b1),
            .o_tvalid(w_tvalid),
            .o_tdata(w_tdata)
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
        reset();

        r_kernel_tvalid <= 1;
        repeat(KERNEL_DEPTH) begin
            @(posedge r_aclk);
        end

        repeat(DEPTH*2) begin
            r_tvalid <= 1'b1;
            @(posedge r_aclk);
            if (r_tvalid && w_tready) begin
                r_tvalid <= 1'b0;
                if (r_tdata == 31)
                    r_tdata <= 0;
                else
                    r_tdata <= r_tdata + 1;
            end
        end
        r_tvalid <= 0;

        repeat(10)
        @(posedge r_aclk);

        $finish();
    end

endmodule