`timescale 1ns/1ps

module Conv2D3x3
    #(parameter
    IN_HEIGHT           = 4, // Input image height in pixels
    IN_WIDTH            = 4, // Input image width in pixels
    IN_CHANNEL          = 2, // Input image channels                REQUIRED: IN_CHANNEL == C*WORDS, for any int C > 0
    WIDTH               = 8, // Width of each AXI4 stream transfer. REQUIRED: WIDTH == C*WORD_WIDTH, for any int C > 0
    WORD_WIDTH          = 8, // Width of each word/value
    FILTERS             = 8, // Number of filters in the kernel     REQUIRED: FILTERS == C*FILTER_PER_LINE, for any int C > 0
    KERNEL_BUF_WIDTH    = 16,// REQUIRED: KERNEL_BUF_WIDTH == C*WIDTH, for any int C > 0

    localparam
    WORDS                       = WIDTH / WORD_WIDTH, // IMPORTANT: must be evenly divisible
    TRANSFERS_PER_PIXEL         = IN_CHANNEL / WORDS, // IMPORTANT: must be evenly divisible
    LINE_BUF_DEPTH              = IN_WIDTH*TRANSFERS_PER_PIXEL,
    WINDOW_ROW_DEPTH            = 3*TRANSFERS_PER_PIXEL,
    MAX_VALID_COUNT             = TRANSFERS_PER_PIXEL*3*IN_WIDTH,
    WINDOW_VALID_COUNT          = TRANSFERS_PER_PIXEL*2*IN_WIDTH + 2*TRANSFERS_PER_PIXEL,
    FILTER_PER_LINE             = KERNEL_BUF_WIDTH / WIDTH, // IMPORTANT: must be evenly divisible
    KERNEL_SEL_PER_TRANSFER     = FILTERS / FILTER_PER_LINE,// IMPORTANT: must be evenly divisible
    KERNEL_BUF_DEPTH            = FILTERS*IN_CHANNEL*WORD_WIDTH / KERNEL_BUF_WIDTH,
    TRANSFERS_PER_IMAGE         = TRANSFERS_PER_PIXEL*IN_HEIGHT*IN_WIDTH,
    OUT_WIDTH                   = WORD_WIDTH*FILTER_PER_LINE,
    PRODUCT_WIDTH               = FILTER_PER_LINE*WORDS*9*WORD_WIDTH, // width of wire to contain all product terms between window and kernel
    PARTIAL_WIDTH               = FILTER_PER_LINE*WORD_WIDTH, // width of wire to contain all parital sums
    NUM_TERMS                   = WORDS*9 // number of terms to sum in to one partial sum
    ) (
    input i_aclk,
    input i_aresetn,

    // input data AXI4 stream interface
    input i_tvalid,
    output o_tready,
    input [WIDTH-1:0] i_tdata,

    // kernel data AXI4 stream interface
    input i_kernel_tvalid,
    output o_kernel_tready,
    input [KERNEL_BUF_WIDTH-1:0] i_kernel_tdata,

    // output data AXI4 stream interface
    output o_tvalid,
    input i_tready,
    output reg [OUT_WIDTH-1:0] o_tdata);

    integer i;
    genvar k, l;


    // Kernel items
    reg [$clog2(KERNEL_BUF_DEPTH)-1:0] r_kernel_sel;            // partial filter group selected from KernelBuffer
    reg [$clog2(KERNEL_SEL_PER_TRANSFER)-1:0] r_kernel_iter;    // partial filter selected from partial filter group
    reg [$clog2(KERNEL_SEL_PER_TRANSFER):0] r_clear_iter;       // index at which r_curr_sum is being cleared
    wire w_kernel_valid;                                        // wire connecting to KernelBuffer indicating if buffer is full/valid

    // KernelBuffer output wires, outputs 9 partial filter groups
    wire [KERNEL_BUF_WIDTH-1:0] w_kernel_00;
    wire [KERNEL_BUF_WIDTH-1:0] w_kernel_01;
    wire [KERNEL_BUF_WIDTH-1:0] w_kernel_02;

    wire [KERNEL_BUF_WIDTH-1:0] w_kernel_10;
    wire [KERNEL_BUF_WIDTH-1:0] w_kernel_11;
    wire [KERNEL_BUF_WIDTH-1:0] w_kernel_12;

    wire [KERNEL_BUF_WIDTH-1:0] w_kernel_20;
    wire [KERNEL_BUF_WIDTH-1:0] w_kernel_21;
    wire [KERNEL_BUF_WIDTH-1:0] w_kernel_22;

    // Window items
    wire w_rd0_valid, w_rd1_valid, w_wr1_valid; // LineBuffer read and write valid status wires
    wire [WIDTH-1:0] w_rd_data0, w_rd_data1;    // LineBuffer read data wires
    wire w_window_valid; // is window valid for convolution
    wire w_window_done; // is the current window done convolving
    wire [PRODUCT_WIDTH-1:0] w_products; // wire containing all multiplication products between window and kernel 
    wire [PARTIAL_WIDTH-1:0] w_partial; // partial sum of the window from w_products

    reg [$clog2(TRANSFERS_PER_PIXEL)-1:0] r_channel_idx; // the channel index at which the input transfer is transfering into  
    reg [$clog2(MAX_VALID_COUNT):0] r_valid_count; // counter indicating the validity of the input window
    reg [$clog2(TRANSFERS_PER_IMAGE):0] r_count; // counter keeping track of the current image transfer count
    reg [$clog2(KERNEL_SEL_PER_TRANSFER):0] r_out_transferred; // number of times the output been transfered
    reg r_transfer_computed; // has current input transfer been computed for its partial sum

    // Window FF RAMs
    reg [WIDTH-1:0] r_window_row0[WINDOW_ROW_DEPTH-1:0];
    reg [WIDTH-1:0] r_window_row1[WINDOW_ROW_DEPTH-1:0];
    reg [WIDTH-1:0] r_window_row2[WINDOW_ROW_DEPTH-1:0];

    // Result Items
    wire [$clog2(FILTERS)-1:0] w_filter_iter;
    wire [$clog2(FILTERS)-1:0] w_out_sel;
    reg [WORD_WIDTH-1:0] r_curr_sums[FILTERS-1:0]; // sum of partial sums

    assign o_tready = (i_tready || !o_tvalid) && w_kernel_valid && w_window_done || !w_window_valid;
    assign w_wr1_valid = (i_tvalid && o_tready);
    assign o_tvalid = r_clear_iter != KERNEL_SEL_PER_TRANSFER && r_out_transferred != KERNEL_SEL_PER_TRANSFER;
    assign w_window_valid = (r_valid_count > WINDOW_VALID_COUNT);
    assign w_window_done = (r_kernel_iter == KERNEL_SEL_PER_TRANSFER-1);
    assign w_filter_iter = (r_kernel_iter * FILTER_PER_LINE);
    assign w_out_sel = (r_out_transferred * FILTER_PER_LINE);


    LineBuffer #(.DEPTH(LINE_BUF_DEPTH), .WIDTH(WIDTH)) line0
    (
        .i_clk(i_aclk),
        .i_resetn(i_aresetn),
        .i_wr_valid(w_rd1_valid),
        .i_wr_data(w_rd_data1),
        .o_rd_valid(w_rd0_valid),
        .o_rd_data(w_rd_data0)
    );

    LineBuffer #(.DEPTH(LINE_BUF_DEPTH), .WIDTH(WIDTH)) line1
    (
        .i_clk(i_aclk),
        .i_resetn(i_aresetn),
        .i_wr_valid(w_wr1_valid),
        .i_wr_data(i_tdata),
        .o_rd_valid(w_rd1_valid),
        .o_rd_data(w_rd_data1)
    );

    KernelBuffer3x3 #(.WIDTH(KERNEL_BUF_WIDTH), .DEPTH(KERNEL_BUF_DEPTH)) kernel
    (
        .i_aclk(i_aclk),
        .i_aresetn(i_aresetn),
        .i_tvalid(i_kernel_tvalid),
        .o_tready(o_kernel_tready),
        .i_tdata(i_kernel_tdata),

        .i_sel(r_kernel_sel),
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

    always @ (posedge i_aclk) begin
        if (!i_aresetn) begin
            r_channel_idx       <= 0;
            r_valid_count       <= 0;
            r_out_transferred   <= 0;
            r_kernel_sel        <= 0;
            r_kernel_iter       <= 0;
            r_count             <= 0;
            r_transfer_computed <= 0;
            r_clear_iter        <= KERNEL_SEL_PER_TRANSFER;

            for (i = 0; i < FILTERS; i = i + 1)
                r_curr_sums[i] <= 0;
        end
        else begin

            // remember if the output has been transfered
            if (i_tready && o_tvalid)
                r_out_transferred <= r_out_transferred + 1;

            if (w_window_valid && w_kernel_valid && !r_transfer_computed) begin
                if (r_kernel_sel == KERNEL_BUF_DEPTH-1)
                    r_kernel_sel <= 0;
                else
                    r_kernel_sel <= r_kernel_sel + 1;

                if (r_clear_iter != KERNEL_SEL_PER_TRANSFER) begin
                    r_clear_iter <= r_clear_iter + 1;

                    for (i = 0; i < FILTER_PER_LINE; i = i + 1)
                        r_curr_sums[w_filter_iter + $unsigned(i)] <= w_partial[WORD_WIDTH*i+:WORD_WIDTH];
                end
                else begin
                    for (i = 0; i < FILTER_PER_LINE; i = i + 1)
                        r_curr_sums[w_filter_iter + $unsigned(i)] <= r_curr_sums[w_filter_iter + $unsigned(i)] + w_partial[WORD_WIDTH*i+:WORD_WIDTH];
                end

                if (w_window_done) begin
                    r_transfer_computed <= 1;
                    if (r_channel_idx == TRANSFERS_PER_PIXEL-1) begin
                        r_out_transferred <= 0;
                        r_clear_iter <= 0;
                    end
                end
                else begin
                    r_kernel_iter <= r_kernel_iter + 1;
                end
            end

            if (w_wr1_valid) begin
                if (w_rd0_valid) begin
                    // shift row 0
                    r_window_row0[WINDOW_ROW_DEPTH-1] <= w_rd_data0;
                    for (i = 0; i < WINDOW_ROW_DEPTH-1; i = i + 1) begin
                        r_window_row0[i] <= r_window_row0[i+1];
                    end
                end

                if (w_rd1_valid) begin
                    // shift row 1
                    r_window_row1[WINDOW_ROW_DEPTH-1] <= w_rd_data1;
                    for (i = 0; i < WINDOW_ROW_DEPTH-1; i = i + 1) begin
                        r_window_row1[i] <= r_window_row1[i+1];
                    end
                end

                // shift row 2
                r_window_row2[WINDOW_ROW_DEPTH-1] <= i_tdata;
                for (i = 0; i < WINDOW_ROW_DEPTH-1; i = i + 1) begin
                    r_window_row2[i] <= r_window_row2[i+1];
                end

                if (r_count != 0) begin
                    if (r_channel_idx == TRANSFERS_PER_PIXEL-1) begin
                        r_channel_idx <= 0;
                    end
                    else begin
                        r_channel_idx <= r_channel_idx + 1;
                    end
                end

                if (r_valid_count == MAX_VALID_COUNT)
                    r_valid_count <= TRANSFERS_PER_PIXEL*2*IN_WIDTH + 1;
                else
                    r_valid_count <= r_valid_count + 1;

                if (r_count == TRANSFERS_PER_IMAGE) begin
                    r_count <= 1;
                    r_valid_count <= 1;
                end
                else
                    r_count <= r_count + 1;

                r_transfer_computed <= 0;
                r_kernel_iter <= 0;
            end
        end
    end


    generate
        for (k = 0; k < FILTER_PER_LINE; k = k + 1) begin
            for (l = 0; l < WORDS; l = l + 1) begin
                assign w_products[WORD_WIDTH*(k*WORDS*9 + l*9 + 0)+: WORD_WIDTH] = (r_window_row0[TRANSFERS_PER_PIXEL*1-1][WORD_WIDTH*l+:WORD_WIDTH] * w_kernel_00[WORD_WIDTH*(k*WORDS+l)+:WORD_WIDTH]);
                assign w_products[WORD_WIDTH*(k*WORDS*9 + l*9 + 1)+: WORD_WIDTH] = (r_window_row0[TRANSFERS_PER_PIXEL*2-1][WORD_WIDTH*l+:WORD_WIDTH] * w_kernel_01[WORD_WIDTH*(k*WORDS+l)+:WORD_WIDTH]);
                assign w_products[WORD_WIDTH*(k*WORDS*9 + l*9 + 2)+: WORD_WIDTH] = (r_window_row0[TRANSFERS_PER_PIXEL*3-1][WORD_WIDTH*l+:WORD_WIDTH] * w_kernel_02[WORD_WIDTH*(k*WORDS+l)+:WORD_WIDTH]);

                assign w_products[WORD_WIDTH*(k*WORDS*9 + l*9 + 3)+: WORD_WIDTH] = (r_window_row1[TRANSFERS_PER_PIXEL*1-1][WORD_WIDTH*l+:WORD_WIDTH] * w_kernel_10[WORD_WIDTH*(k*WORDS+l)+:WORD_WIDTH]);
                assign w_products[WORD_WIDTH*(k*WORDS*9 + l*9 + 4)+: WORD_WIDTH] = (r_window_row1[TRANSFERS_PER_PIXEL*2-1][WORD_WIDTH*l+:WORD_WIDTH] * w_kernel_11[WORD_WIDTH*(k*WORDS+l)+:WORD_WIDTH]);
                assign w_products[WORD_WIDTH*(k*WORDS*9 + l*9 + 5)+: WORD_WIDTH] = (r_window_row1[TRANSFERS_PER_PIXEL*3-1][WORD_WIDTH*l+:WORD_WIDTH] * w_kernel_12[WORD_WIDTH*(k*WORDS+l)+:WORD_WIDTH]);

                assign w_products[WORD_WIDTH*(k*WORDS*9 + l*9 + 6)+: WORD_WIDTH] = (r_window_row2[TRANSFERS_PER_PIXEL*1-1][WORD_WIDTH*l+:WORD_WIDTH] * w_kernel_20[WORD_WIDTH*(k*WORDS+l)+:WORD_WIDTH]);
                assign w_products[WORD_WIDTH*(k*WORDS*9 + l*9 + 7)+: WORD_WIDTH] = (r_window_row2[TRANSFERS_PER_PIXEL*2-1][WORD_WIDTH*l+:WORD_WIDTH] * w_kernel_21[WORD_WIDTH*(k*WORDS+l)+:WORD_WIDTH]);
                assign w_products[WORD_WIDTH*(k*WORDS*9 + l*9 + 8)+: WORD_WIDTH] = (r_window_row2[TRANSFERS_PER_PIXEL*3-1][WORD_WIDTH*l+:WORD_WIDTH] * w_kernel_22[WORD_WIDTH*(k*WORDS+l)+:WORD_WIDTH]);
            end

            TreeAdder #(.WORD_WIDTH(WORD_WIDTH), .NUM_TERMS(NUM_TERMS)) adder
            (
                .i_terms(w_products[WORD_WIDTH*(k*WORDS*9)+:WORD_WIDTH*NUM_TERMS]),
                .o_sum(w_partial[WORD_WIDTH*k+:WORD_WIDTH])
            );
        end
    endgenerate

    always @(*) begin // combinational logic for o_tdata
        for (i = 0; i < FILTER_PER_LINE; i = i + 1) begin
            o_tdata[WORD_WIDTH*i+:WORD_WIDTH] <= r_curr_sums[w_out_sel + $unsigned(i)];
        end
    end



endmodule