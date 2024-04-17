`timescale 1ns/1ps

module Conv2D3x3_TB_2;

    localparam IMG_HEIGHT           = 5;
    localparam IMG_WIDTH            = 4;
    localparam TRANSFERS_PER_PIXEL  = 2;
    localparam WORDS_PER_TRANSFER   = 2;
    localparam FILTERS              = 8;
    localparam WORD_WIDTH           = 8;
    localparam KERNEL_BUF_WIDTH     = 64;

    localparam WIDTH                = WORD_WIDTH*WORDS_PER_TRANSFER;
    localparam IN_CHANNEL           = TRANSFERS_PER_PIXEL*WORDS_PER_TRANSFER;
    localparam NUM_WORDS            = IMG_HEIGHT*IMG_WIDTH*IN_CHANNEL;
    localparam KERNEL_DEPTH         = 3*3*FILTERS*IN_CHANNEL*WORD_WIDTH/KERNEL_BUF_WIDTH;

    reg r_aclk                          = 0; 
    reg r_aresetn                       = 1;
    reg r_img_tvalid                    = 0;
    reg [WORD_WIDTH-1:0] r_img_tdata    = 0;
    reg r_kernel_tvalid                 = 0;
    reg [KERNEL_BUF_WIDTH-1:0] r_kernel_tdata           = 64'h0101010101010101;

    wire [WIDTH-1:0] w_in_tdata;
    wire w_img_tready;
    wire w_kernel_tready;
    wire w_out_tvalid;
    wire [KERNEL_BUF_WIDTH / WORDS_PER_TRANSFER-1:0] w_out_tdata;

    Conv2D3x3 #(
        .IMG_HEIGHT(IMG_HEIGHT), 
        .IMG_WIDTH(IMG_WIDTH), 
        .TRANSFERS_PER_PIXEL(TRANSFERS_PER_PIXEL), 
        .WORDS_PER_TRANSFER(WORDS_PER_TRANSFER), 
        .FILTERS(FILTERS)) UUT
        (
            .i_aclk(r_aclk),
            .i_aresetn(r_aresetn),
            .i_img_tvalid(r_img_tvalid),
            .o_img_tready(w_img_tready),
            .i_img_tdata(w_in_tdata),

            .i_kernel_tvalid(r_kernel_tvalid),
            .o_kernel_tready(w_kernel_tready),
            .i_kernel_tdata(r_kernel_tdata),

            .i_out_tready(1'b1),
            .o_out_tvalid(w_out_tvalid),
            .o_out_tdata(w_out_tdata)
        );

    genvar j;
    generate
        for (j = 0; j < WORDS_PER_TRANSFER; j++) begin
            assign w_in_tdata[WORD_WIDTH*j+: WORD_WIDTH] = r_img_tdata + j;
        end
    endgenerate

    // 100mhz clock
    always #5 r_aclk <= !r_aclk;

    task reset_UUT();
        @(posedge r_aclk);
        r_aresetn <= 0;
        @(posedge r_aclk);
        r_aresetn <= 1;
        @(posedge r_aclk);
    endtask

    task fill_kernel();
        r_kernel_tvalid <= 1;
        for (int i = 0; i < KERNEL_DEPTH; i++) begin
            if (w_kernel_tready != 1) // check that kernel is accepting
                $error("Fill Kernel[%d]: EXPECTED w_kernel_tready == 1 but got %d", i, w_kernel_tready);
            @(posedge r_aclk);
        end
        r_kernel_tvalid <= 0;
        @(posedge r_aclk);
    endtask

    task fill_input();
        r_img_tdata <= 0;
        @(posedge r_aclk);
        while (r_img_tdata < NUM_WORDS-WORDS_PER_TRANSFER) begin
            r_img_tvalid <= 1;
            @(posedge r_aclk);
            while (!w_img_tready) begin
                @(posedge r_aclk);
            end
            r_img_tdata <= r_img_tdata + WORDS_PER_TRANSFER;
            r_img_tvalid <= 0;
        end
    endtask

    initial begin
        reset_UUT();

        // After reset checks. 
        if (w_img_tready != 1)
            $error("EXPECTED w_img_tready == 1 but got %d", w_img_tready); 

        if (w_kernel_tready != 1)
            $error("EXPECTED w_kernel_tready == 1 but got %d", w_kernel_tready);

        if (w_out_tvalid != 0)
            $error("EXPECTED w_out_tvalid == 0 but got %d", w_out_tvalid); 
        
        // Fill kernel
        fill_kernel();

        // Assert that kernel is no longer accepting
        if (w_kernel_tready != 0)
            $error("LEXPECTED w_kernel_tready == 0 but got %d", w_kernel_tready);

        // fill the input image twice
        fill_input();
        fill_input();

        // Assert that UUT is ready for new image
        if (w_img_tready != 1)
            $error("EXPECTED w_img_tready == 1 but got %d", w_img_tready);

        // some exit padding
        repeat(10) @(posedge r_aclk);

        $finish();
    end

endmodule