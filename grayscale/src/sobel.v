
`timescale 1 ns/1 ns

//end up with sobel pixels out = pixels in
//when 3x3, pad edges with 1 pixel
//c code just sets edges to 0??

module sobel(clock, reset, fifo_in_rd_en, fifo_in_dout, fifo_in_empty, fifo_out_wr_en, fifo_out_din, fifo_out_full);

    parameter integer FIFO_DWIDTH_IN; //this will be 8*9?
    parameter integer FIFO_DWIDTH_OUT; //this will be 8?

    input wire clock;
    input wire reset;

    // input fifo
    output reg fifo_in_rd_en;
    input wire [(FIFO_DWIDTH_IN - 1):0] fifo_in_dout;
    input wire fifo_in_empty;

    // output fifo
    output reg fifo_out_wr_en;
    output reg [(FIFO_DWIDTH_OUT - 1):0] fifo_out_din;
    input wire fifo_out_full;

    always @(posedge clock, posedge reset) begin
        
    end

    always @* begin
        
    end

endmodule
