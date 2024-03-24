`timescale 1ns/1ps

module LineBuffer #(parameter DEPTH = 1024, WIDTH = 8) (
    input                   i_clk,
    input                   i_resetn,
    input                   i_wr_valid,
    input [WIDTH-1:0]       i_wr_data,
    output                  o_rd_valid,
    output reg [WIDTH-1:0]  o_rd_data);

    reg [$clog2(DEPTH)-1:0] r_wr_addr, r_rd_addr;
    reg [$clog2(DEPTH):0] r_count; // one extra bit
    
    // the actual buffer
    reg [WIDTH-1:0] r_buf[DEPTH-1:0];

    always @ (posedge i_clk) begin
        if (!i_resetn) begin
            // synchronous reset logic
            r_count <= 0;
            r_wr_addr <= 0;
            r_rd_addr <= 0;
        end
        else begin
            if (i_wr_valid) begin
                // write data
                r_buf[r_wr_addr] <= i_wr_data;

                // update write address
                if (r_wr_addr == DEPTH-1)
                    r_wr_addr <= 0;
                else
                    r_wr_addr <= r_wr_addr + 1;

                // update read address
                if (r_count >= DEPTH-1) begin
                    if (r_rd_addr == DEPTH-1)
                        r_rd_addr <= 0;
                    else
                        r_rd_addr <= r_rd_addr + 1;
                end

                // update count
                if (r_count != DEPTH) begin
                    r_count <= r_count + 1;
                end
                
                // read data
                o_rd_data <= r_buf[r_rd_addr];
            end
        end
    end

    assign o_rd_valid = (r_count == DEPTH);


endmodule