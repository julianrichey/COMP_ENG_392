/*
architecture

rgb fifo (width=24, depth=2)
grayscale
grayscale fifo (width=8, depth=2)
sobel, sobel_op
sobel fifo (width=8, depth=2)
*/

`timescale 1 ns / 1 ns

module dut_system #(
    parameter integer IMG_WIDTH,
    parameter integer IMG_HEIGHT,
    parameter integer RGB_DWIDTH,
    parameter integer RGB_BUFFER,
    parameter integer GRAYSCALE_DWIDTH,
    parameter integer GRAYSCALE_BUFFER,
    parameter integer SOBEL_DWIDTH,
    parameter integer SOBEL_BUFFER
) (
    input clock,
    input reset,

    //rbg memory to rgb fifo
    input fifo_rgb_wr_en,
    input [RGB_DWIDTH-1:0] fifo_rgb_din,
    output fifo_rgb_full,

    //sobel fifo to sobel memory
    input fifo_sobel_rd_en,
    output [SOBEL_DWIDTH-1:0] fifo_sobel_dout,
    output fifo_sobel_empty
);

    //rgb fifo to grayscale
    wire fifo_rgb_rd_en;
    wire [RGB_DWIDTH-1:0] fifo_rgb_dout;
    wire fifo_rgb_empty;

    //grayscale to grayscale fifo
    wire fifo_grayscale_wr_en;
    wire [GRAYSCALE_DWIDTH-1:0] fifo_grayscale_din;
    wire fifo_grayscale_full;

    //grayscale fifo to sobel
    wire fifo_grayscale_rd_en;
    wire [GRAYSCALE_DWIDTH-1:0] fifo_grayscale_dout;
    wire fifo_grayscale_empty;

    //sobel to sobel fifo
    wire fifo_sobel_wr_en;
    wire [SOBEL_DWIDTH-1:0] fifo_sobel_din;
    wire fifo_sobel_full;



    fifo #(
        .FIFO_DATA_WIDTH(RGB_DWIDTH),
        .FIFO_BUFFER_SIZE(RGB_BUFFER)
    ) fifo_rgb (
        .rd_clk(clock),
        .wr_clk(clock),
        .reset(reset),
        .rd_en(fifo_rgb_rd_en),
        .wr_en(fifo_rgb_wr_en),
        .din(fifo_rgb_din),
        .dout(fifo_rgb_dout),
        .full(fifo_rgb_full),
        .empty(fifo_rgb_empty)
    );

    grayscale #(
        .DWIDTH_IN(RGB_DWIDTH),
        .DWIDTH_OUT(GRAYSCALE_DWIDTH)
    ) grayscale_0 (
        .clock(clock),
        .reset(reset),
        .fifo_in_rd_en(fifo_rgb_rd_en),
        .fifo_in_dout(fifo_rgb_dout),
        .fifo_in_empty(fifo_rgb_empty),
        .fifo_out_wr_en(fifo_grayscale_wr_en),
        .fifo_out_din(fifo_grayscale_din),
        .fifo_out_full(fifo_grayscale_full)
    );

    fifo #(
        .FIFO_DATA_WIDTH(GRAYSCALE_DWIDTH),
        .FIFO_BUFFER_SIZE(GRAYSCALE_BUFFER)
    ) fifo_grayscale (
        .rd_clk(clock),
        .wr_clk(clock),
        .reset(reset),
        .rd_en(fifo_grayscale_rd_en),
        .wr_en(fifo_grayscale_wr_en),
        .din(fifo_grayscale_din),
        .dout(fifo_grayscale_dout),
        .full(fifo_grayscale_full),
        .empty(fifo_grayscale_empty)
    );

    sobel #(
        .DWIDTH_IN(GRAYSCALE_DWIDTH),
        .DWIDTH_OUT(SOBEL_DWIDTH)
        .IMG_WIDTH(IMG_HEIGHT),
        .IMG_HEIGHT(IMG_WIDTH)
    ) sobel_0 (
        .clock(clock),
        .reset(reset),
        .in_rd_en(fifo_grayscale_rd_en),
        .in_dout(fifo_grayscale_dout),
        .in_empty(fifo_grayscale_empty),
        .out_wr_en(fifo_sobel_wr_en),
        .out_din(fifo_sobel_din),
        .out_full(fifo_sobel_full)
    );

    fifo #(
        .FIFO_DATA_WIDTH(SOBEL_DWIDTH),
        .FIFO_BUFFER_SIZE(SOBEL_BUFFER)
    ) fifo_sobel (
        .rd_clk(clock),
        .wr_clk(clock),
        .reset(reset),
        .rd_en(fifo_sobel_rd_en),
        .wr_en(fifo_sobel_wr_en),
        .din(fifo_sobel_din),
        .dout(fifo_sobel_dout),
        .full(fifo_sobel_full),
        .empty(fifo_sobel_empty)
    );

endmodule
