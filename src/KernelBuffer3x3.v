`timescale 1ns/1ps

module KernelBuffer3x3 #(parameter 
    WIDTH   = 16,
    DEPTH   = 512
    ) (
    input i_aclk,
    input i_aresetn,

    // AXI4 stream interface
    input i_tvalid,
    output o_tready,
    input [WIDTH-1:0] i_tdata,
    
    // kernel output
    input [$clog2(DEPTH)-1:0] i_sel,
    output o_kernel_valid,
    output reg [WIDTH-1:0] o_kernel_00, 
    output reg [WIDTH-1:0] o_kernel_01, 
    output reg [WIDTH-1:0] o_kernel_02,

    output reg [WIDTH-1:0] o_kernel_10, 
    output reg [WIDTH-1:0] o_kernel_11, 
    output reg [WIDTH-1:0] o_kernel_12,
    
    output reg [WIDTH-1:0] o_kernel_20, 
    output reg [WIDTH-1:0] o_kernel_21, 
    output reg [WIDTH-1:0] o_kernel_22);

    localparam VALID_COUNT = 3*3*DEPTH;     // number of words in buffers for kernel to be valid
    
    reg [$clog2(DEPTH)-1:0] r_sel;          // select used during filling
    reg [$clog2(VALID_COUNT):0] r_count;    // number of valid words in buffers

    // Kernel BRAMs, ordered (Height, Width, Kernels, Channels)
    reg [WIDTH-1:0] r_buf_00[DEPTH-1:0];
    reg [WIDTH-1:0] r_buf_01[DEPTH-1:0];
    reg [WIDTH-1:0] r_buf_02[DEPTH-1:0];

    reg [WIDTH-1:0] r_buf_10[DEPTH-1:0];
    reg [WIDTH-1:0] r_buf_11[DEPTH-1:0];
    reg [WIDTH-1:0] r_buf_12[DEPTH-1:0];

    reg [WIDTH-1:0] r_buf_20[DEPTH-1:0];
    reg [WIDTH-1:0] r_buf_21[DEPTH-1:0];
    reg [WIDTH-1:0] r_buf_22[DEPTH-1:0];

    assign o_tready = (r_count < VALID_COUNT);
    assign o_kernel_valid = (r_count == VALID_COUNT);

    always @(posedge i_aclk) begin
        o_kernel_00 <= r_buf_00[i_sel];
        o_kernel_01 <= r_buf_01[i_sel];
        o_kernel_02 <= r_buf_02[i_sel];
        o_kernel_10 <= r_buf_10[i_sel];
        o_kernel_11 <= r_buf_11[i_sel];
        o_kernel_12 <= r_buf_12[i_sel];
        o_kernel_20 <= r_buf_20[i_sel];
        o_kernel_21 <= r_buf_21[i_sel];
        o_kernel_22 <= r_buf_22[i_sel];
    end

    always @(posedge i_aclk) begin
        if (!i_aresetn) begin
            r_count <= 0;
            r_sel <= 0;
        end
        else begin
            if (i_tvalid && o_tready) begin
                r_count <= r_count + 1;

                if (r_sel == DEPTH-1)
                    r_sel <= 0;
                else
                    r_sel <= r_sel + 1;

                // fill into 9 BRAMs
                if (r_count < DEPTH)
                    r_buf_00[r_sel] <= i_tdata;
                else if (r_count < DEPTH*2)
                    r_buf_01[r_sel] <= i_tdata;
                else if (r_count < DEPTH*3)
                    r_buf_02[r_sel] <= i_tdata;
                else if (r_count < DEPTH*4)
                    r_buf_10[r_sel] <= i_tdata;
                else if (r_count < DEPTH*5)
                    r_buf_11[r_sel] <= i_tdata;
                else if (r_count < DEPTH*6)
                    r_buf_12[r_sel] <= i_tdata;
                else if (r_count < DEPTH*7)
                    r_buf_20[r_sel] <= i_tdata;
                else if (r_count < DEPTH*8)
                    r_buf_21[r_sel] <= i_tdata;
                else
                    r_buf_22[r_sel] <= i_tdata;
            end
        end
    end

endmodule