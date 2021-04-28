/*

architecture

rgb fifo
grayscale
grayscale fifo
padding
padding fifo
sobel, sobel_op
sobel fifo


*/

`timescale 1 ns / 1 ns

module dut_system #(
    parameter integer IMG_WIDTH = 720,
    parameter integer IMG_HEIGHT = 540,
    parameter integer RGB_DWIDTH = 24,
    parameter integer RGB_BUFFER = 16,
    parameter integer GRAYSCALE_DWIDTH = 8,
    parameter integer GRAYSCALE_BUFFER = 16,
    parameter integer PADDING_DWIDTH = 8,
    parameter integer PADDING_BUFFER = 16,
    parameter integer SOBEL_DWIDTH = 8,
    parameter integer SOBEL_BUFFER = 16
) (
    input clock,
    input reset,

    //rbg memory to rgb fifo
    input fifo_in_wr_en,
    input [RGB_DWIDTH-1:0] fifo_in_din,
    output fifo_in_full,

    //sobel fifo to sobel memory
    input fifo_out_rd_en,
    output [SOBEL_DWIDTH-1:0] fifo_out_dout,
    output fifo_out_empty
);


    localparam integer NUM_FIFOS = 4;
    
    wire fifo_rd_en [0:NUM_FIFOS-1];
    wire [7:0] fifo_dout [0:NUM_FIFOS-1];
    wire fifo_empty [0:NUM_FIFOS-1];

    wire fifo_wr_en [0:NUM_FIFOS-1];
    wire [7:0] fifo_din [0:NUM_FIFOS-1];
    wire fifo_full [0:NUM_FIFOS-1];

    assign fifo_rd_en[3] = fifo_out_rd_en;
    assign fifo_out_dout = fifo_dout[3];
    assign fifo_out_empty = fifo_empty[3];


    grayscale #(
        .FIFO_DWIDTH_IN(RGB_DWIDTH),
        .FIFO_DWIDTH_OUT(GRAYSCALE_DWIDTH)
    ) grayscale_0 (
        .clock(clock),
        .reset(reset),
        .fifo_in_rd_en(fifo_rd_en[0]),
        .fifo_in_dout(fifo_dout[0]),
        .fifo_in_empty(fifo_empty[0]),
        .fifo_out_wr_en(fifo_wr_en[1]),
        .fifo_out_din(fifo_din[1]),
        .fifo_out_full(fifo_full[1])
    );

    padding #(
        .IMG_WIDTH(IMG_WIDTH),
        .IMG_HEIGHT(IMG_HEIGHT)
    ) padding_0 (
        .clock(clock),
        .reset(reset),
        .in_rd_en(fifo_rd_en[1]),
        .in_dout(fifo_dout[1]),
        .in_empty(fifo_empty[1]),
        .out_wr_en(fifo_wr_en[2]),
        .out_din(fifo_din[2]),
        .out_full(fifo_full[2])
    );

    sobel #(
        .IMG_WIDTH(IMG_WIDTH),
        .IMG_HEIGHT(IMG_HEIGHT)
    ) sobel_0 (
        .clock(clock),
        .reset(reset),
        .in_rd_en(fifo_rd_en[2]),
        .in_dout(fifo_dout[2]),
        .in_empty(fifo_empty[2]),
        .out_wr_en(fifo_wr_en[3]),
        .out_din(fifo_din[3]),
        .out_full(fifo_full[3])
    );

    fifo #(
        .FIFO_DATA_WIDTH(RGB_DWIDTH),
        .FIFO_BUFFER_SIZE(RGB_BUFFER)
    ) fifo_rgb (
        .rd_clk(clock),
        .wr_clk(clock),
        .reset(reset),

        .wr_en(fifo_in_wr_en),
        .din(fifo_in_din),
        .full(fifo_in_full),

        .rd_en(fifo_in_rd_en),
        .dout(fifo_in_dout),
        .empty(fifo_in_empty)
    );

    genvar i;
    generate 
        for (i=0; i<NUM_FIFOS; i=i+1) begin

            fifo #(
                .FIFO_DATA_WIDTH(8),
                .FIFO_BUFFER_SIZE(8)
            ) fifos (
                .rd_clk(clock),
                .wr_clk(clock),
                .reset(reset),
                .rd_en(fifo_rd_en[i]),
                .wr_en(fifo_wr_en[i]),
                .din(fifo_din[i]),
                .dout(fifo_dout[i]),
                .full(fifo_full[i]),
                .empty(fifo_empty[i])
            );
        end
    endgenerate

endmodule
