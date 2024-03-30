`timescale 1ns/1ps

module KernelBuffer3x3_TB;

    localparam WIDTH = 8;
    localparam DEPTH = 8;

    // UUT inputs
    reg r_aclk                      = 1'b0;
    reg r_aresetn                   = 1'b1;
    reg r_tvalid                    = 1'b0;
    reg [WIDTH-1:0] r_tdata         = 0;
    reg [$clog2(DEPTH)-1:0] r_sel   = 0;
    
    // UUT outputs
    wire w_tready;
    wire w_kernel_valid;

    wire [WIDTH-1:0] w_kernel_00;
    wire [WIDTH-1:0] w_kernel_01;
    wire [WIDTH-1:0] w_kernel_02;

    wire [WIDTH-1:0] w_kernel_10;
    wire [WIDTH-1:0] w_kernel_11;
    wire [WIDTH-1:0] w_kernel_12;

    wire [WIDTH-1:0] w_kernel_20;
    wire [WIDTH-1:0] w_kernel_21;
    wire [WIDTH-1:0] w_kernel_22;


    KernelBuffer3x3 #(
        .WIDTH(WIDTH),
        .WIDTH(WIDTH), 
        .DEPTH(DEPTH)) UUT 
    (
        .i_aclk(r_aclk),
        .i_aresetn(r_aresetn),
        .i_tvalid(r_tvalid),
        .o_tready(w_tready),
        .i_tdata(r_tdata),

        .i_sel(r_sel),
        .o_kernel_valid(w_kernel_valid),

        .o_kernel_00(w_kernel_00),
        .o_kernel_01(w_kernel_01),
        .o_kernel_02(w_kernel_02),

        .o_kernel_10(w_kernel_10),
        .o_kernel_11(w_kernel_11),
        .o_kernel_12(w_kernel_12),

        .o_kernel_20(w_kernel_20),
        .o_kernel_21(w_kernel_21),
        .o_kernel_22(w_kernel_22)
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
        // reset kernel
        reset();

        repeat(9*DEPTH) begin
            r_tvalid <= 1'b1;
            @(posedge r_aclk);
            if (w_tready) begin
                r_tvalid <= 1'b0;
                r_tdata <= r_tdata + 1;
            end
        end

        repeat(DEPTH) begin
            @(posedge r_aclk);
            r_sel <= r_sel + 1;
        end
        @(posedge r_aclk);

        $finish();
    end

endmodule