`timescale 1ns/1ps

// NOTE: Can handle odd number of terms
module TreeAdder #(parameter WORD_WIDTH = 8, NUM_TERMS = 4) (
    input [WORD_WIDTH*NUM_TERMS-1:0] i_terms,
    output [WORD_WIDTH-1:0] o_sum);

    localparam NUM_BASE_SUM = NUM_TERMS/2;
    localparam RESIDUAL = NUM_TERMS % 2;
    localparam NUM_SUM = NUM_TERMS-1;

    wire [WORD_WIDTH*NUM_SUM-1:0] w_partial;

    assign o_sum = w_partial[WORD_WIDTH*(NUM_SUM-1)+:WORD_WIDTH];

    genvar i;
    generate

        // sum base level terms
        for (i = 0; i < NUM_BASE_SUM; i = i + 1) begin
            assign w_partial[WORD_WIDTH*i+:WORD_WIDTH] = i_terms[WORD_WIDTH*(i*2)+:WORD_WIDTH] + i_terms[WORD_WIDTH*(i*2+1)+:WORD_WIDTH];
        end

        for (i = NUM_BASE_SUM; i < NUM_SUM; i = i + 1) begin

            // case 1: summing odd number of terms, handle the extra term
            if (RESIDUAL == 1 && (i-NUM_BASE_SUM)*2+1 == NUM_BASE_SUM || (i-NUM_BASE_SUM)*2 == NUM_BASE_SUM)
                assign w_partial[WORD_WIDTH*i+:WORD_WIDTH] = w_partial[WORD_WIDTH*((i-NUM_BASE_SUM)*2)+:WORD_WIDTH] 
                    + i_terms[WORD_WIDTH*(NUM_TERMS-1)+:WORD_WIDTH];

            // case 2: summing odd number of terms, handle the shifted indexing of the rest of terms due to extra term
            else if (RESIDUAL == 1 && (i-NUM_BASE_SUM)*2+1 > NUM_BASE_SUM)
                assign w_partial[WORD_WIDTH*i+:WORD_WIDTH] = w_partial[WORD_WIDTH*((i-NUM_BASE_SUM)*2-1)+:WORD_WIDTH] 
                    + w_partial[WORD_WIDTH*((i-NUM_BASE_SUM)*2)+:WORD_WIDTH];
            
            // case 3: summing even number of terms
            else
                assign w_partial[WORD_WIDTH*i+:WORD_WIDTH] = w_partial[WORD_WIDTH*((i-NUM_BASE_SUM)*2)+:WORD_WIDTH] 
                    + w_partial[WORD_WIDTH*((i-NUM_BASE_SUM)*2+1)+:WORD_WIDTH];
        end
        
    endgenerate



endmodule