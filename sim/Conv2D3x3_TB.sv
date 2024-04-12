`timescale 1ns/1ps

module Conv2D3x3_TB;

    localparam IN_HEIGHT    = 4;
    localparam IN_WIDTH     = 4;
    localparam IN_CHANNEL   = 2;
    localparam WORDS        = 1;
    localparam WORD_WIDTH   = 8; 
    localparam FILTERS      = 8;
    localparam KERNEL_BUF_WIDTH = 32;

    localparam WIDTH            = WORD_WIDTH * WORDS;
    localparam NUM_WORDS        = IN_HEIGHT*IN_WIDTH*IN_CHANNEL;
    localparam KERNEL_DEPTH     = 3*3*FILTERS*IN_CHANNEL*WORD_WIDTH/KERNEL_BUF_WIDTH;
    localparam FILTER_PER_LINE  = KERNEL_BUF_WIDTH / WIDTH;

    reg r_aclk                      = 0; 
    reg r_aresetn                   = 1;
    reg r_tvalid                    = 0;
    reg [WORD_WIDTH-1:0] r_tdata    = 0;
    reg r_kernel_tvalid             = 0;
    reg [63:0] r_kernel_tdata       = 64'h0101010101010101;

    wire w_tready;
    wire w_kernel_tready;
    wire w_tvalid;
    wire [FILTER_PER_LINE*WORD_WIDTH-1:0] w_tdata;

    Conv2D3x3 #(
        .IN_HEIGHT(IN_HEIGHT), 
        .IN_WIDTH(IN_WIDTH), 
        .IN_CHANNEL(IN_CHANNEL), 
        .WORDS(WORDS), 
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
        r_tdata <= 0;
        @(posedge r_aclk);
        while (r_tdata != NUM_WORDS-1) begin
            r_tvalid <= 1;
            @(posedge r_aclk);
            while (!w_tready) begin
                @(posedge r_aclk);
            end
            r_tdata <= r_tdata + 1;
            r_tvalid <= 0;
        end
    endtask

    initial begin
        reset_UUT();

        // After reset checks. 
        if (w_tready != 1)
            $error("EXPECTED w_tready == 1 but got %d", w_tready); 

        if (w_kernel_tready != 1)
            $error("EXPECTED w_kernel_tready == 1 but got %d", w_kernel_tready);

        if (w_tvalid != 0)
            $error("EXPECTED w_tvalid == 0 but got %d", w_tvalid); 
        
        // Fill kernel
        fill_kernel();

        // Assert that kernel is no longer accepting
        if (w_kernel_tready != 0)
            $error("LEXPECTED w_kernel_tready == 0 but got %d", w_kernel_tready);

        // fill the input image twice
        fill_input();
        fill_input();

        // Assert that UUT is ready for new image
        if (w_tready != 1)
            $error("EXPECTED w_tready == 1 but got %d", w_tready);

        // some exit padding
        repeat(10) @(posedge r_aclk);

        $finish();
    end

endmodule