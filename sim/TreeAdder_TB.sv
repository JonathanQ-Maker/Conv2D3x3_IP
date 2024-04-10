`timescale 1ns/1ps

module TreeAdder_TB;

    localparam WORD_WIDTH = 8;
    localparam NUM_TERMS = 7;
    localparam SERIES_SUM = (NUM_TERMS/2.0)*(NUM_TERMS-1); // arithmetic series sum

    reg [WORD_WIDTH*NUM_TERMS-1:0] r_terms;
    wire [WORD_WIDTH-1:0] w_sum;

    TreeAdder #(.WORD_WIDTH(WORD_WIDTH), .NUM_TERMS(NUM_TERMS)) UUT 
    (
        .i_terms(r_terms),
        .o_sum(w_sum)
    );


    integer i;

    initial begin

        // fill terms with arithmatic series
        for (i = 0; i < NUM_TERMS; i = i + 1) begin
            r_terms[i*WORD_WIDTH+:WORD_WIDTH] <= i;
        end

        #50;

        if (w_sum != SERIES_SUM)
            $error("EXPECETED %d BUT GOT %d", SERIES_SUM, w_sum);
        else
            $display("TEST PASSED");

        $finish();
    end

endmodule