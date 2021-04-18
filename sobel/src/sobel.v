
`timescale 1 ns/1 ns

module sobel(clock, reset, fifo_in_rd_en, fifo_in_dout, fifo_in_empty, fifo_out_wr_en, fifo_out_din, fifo_out_full);


    parameter integer SOBEL_DWIDTH_IN; //8*9 bits. 1D array, not 2D, so that we don't have to change fifo or anything.
    parameter integer SOBEL_DWIDTH_OUT; //8 bits

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

    reg [FIFO_DWIDTH_OUT-1:0] data, data_c;
    reg is_data, is_data_c;

    always @(posedge clock, posedge reset) begin
        
    end

    always @* begin
        
    end

endmodule
