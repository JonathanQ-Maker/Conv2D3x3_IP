`timescale 1ns/1ps

module KernelBuffer3x3 #(parameter 
    WIDTH           = 16,
    BUFFER_WIDTH    = 64, // REQUIRED: BUFFER_WIDTH == C*WIDTH, for any C > 0
    BUFFER_DEPTH    = 512
    ) (
    input i_aclk,
    input i_aresetn,

    // AXI4 stream interface
    input i_tvalid,
    output o_tready,
    input [WIDTH-1:0] i_tdata,
    
    // kernel output
    input [$clog2(BUFFER_DEPTH)-1:0] i_sel,
    output o_buf_valid,
    output reg [BUFFER_WIDTH-1:0] o_buf_00, 
    output reg [BUFFER_WIDTH-1:0] o_buf_01, 
    output reg [BUFFER_WIDTH-1:0] o_buf_02,

    output reg [BUFFER_WIDTH-1:0] o_buf_10, 
    output reg [BUFFER_WIDTH-1:0] o_buf_11, 
    output reg [BUFFER_WIDTH-1:0] o_buf_12,
    
    output reg [BUFFER_WIDTH-1:0] o_buf_20, 
    output reg [BUFFER_WIDTH-1:0] o_buf_21, 
    output reg [BUFFER_WIDTH-1:0] o_buf_22);

    localparam VALID_COUNT = 3*3*BUFFER_DEPTH;  // number of words in buffers for kernel to be valid
    localparam SHIFT_COUNT = BUFFER_WIDTH/WIDTH;// MUST BE EVENLY DIVISIBLE
    
    reg [$clog2(BUFFER_DEPTH)-1:0] r_sel;       // select used during filling
    reg [$clog2(VALID_COUNT):0] r_count;        // number of valid words in buffers
    reg [BUFFER_WIDTH-1:0] r_shift;             // WIDTH to BUFFER_WIDTH shift registers
    reg [$clog2(SHIFT_COUNT):0] r_shift_count; // number of valid bits in shift registers

    // Kernel BRAMs, ordered (Height, Width, Kernels, Channels)
    reg [BUFFER_WIDTH-1:0] r_buf_00[BUFFER_DEPTH-1:0];
    reg [BUFFER_WIDTH-1:0] r_buf_01[BUFFER_DEPTH-1:0];
    reg [BUFFER_WIDTH-1:0] r_buf_02[BUFFER_DEPTH-1:0];

    reg [BUFFER_WIDTH-1:0] r_buf_10[BUFFER_DEPTH-1:0];
    reg [BUFFER_WIDTH-1:0] r_buf_11[BUFFER_DEPTH-1:0];
    reg [BUFFER_WIDTH-1:0] r_buf_12[BUFFER_DEPTH-1:0];

    reg [BUFFER_WIDTH-1:0] r_buf_20[BUFFER_DEPTH-1:0];
    reg [BUFFER_WIDTH-1:0] r_buf_21[BUFFER_DEPTH-1:0];
    reg [BUFFER_WIDTH-1:0] r_buf_22[BUFFER_DEPTH-1:0];

    assign o_tready = (r_count < VALID_COUNT);
    assign o_buf_valid = (r_count == VALID_COUNT);

    always @(posedge i_aclk) begin
        o_buf_00 <= r_buf_00[i_sel];
        o_buf_01 <= r_buf_01[i_sel];
        o_buf_02 <= r_buf_02[i_sel];
        o_buf_10 <= r_buf_10[i_sel];
        o_buf_11 <= r_buf_11[i_sel];
        o_buf_12 <= r_buf_12[i_sel];
        o_buf_20 <= r_buf_20[i_sel];
        o_buf_21 <= r_buf_21[i_sel];
        o_buf_22 <= r_buf_22[i_sel];
    end

    always @(posedge i_aclk) begin
        if (!i_aresetn) begin
            r_count <= 0;
            r_shift_count <= 0;
            r_sel <= 0;
        end
        else begin
            if (i_tvalid && o_tready) begin
                // WIDTH to BUFFER_WIDTH conversion
                r_shift <= {i_tdata, r_shift[BUFFER_WIDTH-1:WIDTH]};

                if (r_shift_count == SHIFT_COUNT) begin
                    r_shift_count <= 1;
                    r_count <= r_count + 1;

                    if (r_sel == BUFFER_DEPTH-1)
                        r_sel <= 0;
                    else
                        r_sel <= r_sel + 1;

                    // fill into 9 BRAMs
                    if (r_count < BUFFER_DEPTH)
                        r_buf_00[r_sel] <= r_shift;
                    else if (r_count < BUFFER_DEPTH*2)
                        r_buf_01[r_sel] <= r_shift;
                    else if (r_count < BUFFER_DEPTH*3)
                        r_buf_02[r_sel] <= r_shift;
                    else if (r_count < BUFFER_DEPTH*4)
                        r_buf_10[r_sel] <= r_shift;
                    else if (r_count < BUFFER_DEPTH*5)
                        r_buf_11[r_sel] <= r_shift;
                    else if (r_count < BUFFER_DEPTH*6)
                        r_buf_12[r_sel] <= r_shift;
                    else if (r_count < BUFFER_DEPTH*7)
                        r_buf_20[r_sel] <= r_shift;
                    else if (r_count < BUFFER_DEPTH*8)
                        r_buf_21[r_sel] <= r_shift;
                    else
                        r_buf_22[r_sel] <= r_shift;
                end
                else begin
                    r_shift_count <= r_shift_count + 1;
                end
            end
        end
    end

endmodule