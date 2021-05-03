/*
architecture

rgb fifo (width=24, depth=2)
grayscale
grayscale fifo (width=8, depth=2)
op_padder, op_gaussian
gaussian fifo
op_padder, op_sobel
sobel fifo (width=8, depth=2)
*/

`timescale 1 ns / 1 ns

module dut_system #(
    parameter integer USE_GAUSSIAN,
    parameter integer USE_SOBEL,
    parameter integer IMG_WIDTH,
    parameter integer IMG_HEIGHT,
    parameter integer RGB_DWIDTH,
    parameter integer DWIDTH,
    parameter integer BUFFER
) (
    input clock,
    input reset,

    //rbg memory to rgb fifo
    input fifo_in_wr_en,
    input [RGB_DWIDTH-1:0] fifo_in_din,
    output fifo_in_full,

    //sobel fifo to sobel memory
    input fifo_out_rd_en,
    output [DWIDTH-1:0] fifo_out_dout,
    output fifo_out_empty
);

    //1 for input to grayscale, 1 for output from grayscale. 
    //1 additional for each additional module enabled
    localparam integer NUM_FIFOS = 2 + USE_GAUSSIAN + USE_SOBEL;

    wire fifo_in_rd_en;
    wire [RGB_DWIDTH - 1:0] fifo_in_dout;
    wire fifo_in_empty;

    wire fifo_rd_en [0:NUM_FIFOS-2];
    wire [DWIDTH-1:0] fifo_dout [0:NUM_FIFOS-2];
    wire fifo_empty [0:NUM_FIFOS-2];

    wire fifo_wr_en [0:NUM_FIFOS-2];
    wire [DWIDTH-1:0] fifo_din [0:NUM_FIFOS-2];
    wire fifo_full [0:NUM_FIFOS-2];

    assign fifo_rd_en[NUM_FIFOS-2] = fifo_out_rd_en;
    assign fifo_out_dout = fifo_dout[NUM_FIFOS-2];
    assign fifo_out_empty = fifo_empty[NUM_FIFOS-2];


    fifo #(
        .FIFO_DATA_WIDTH(RGB_DWIDTH),
        .FIFO_BUFFER_SIZE(BUFFER)
    ) fifo_in (
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

    grayscale #(
        .DWIDTH_IN(RGB_DWIDTH),
        .DWIDTH_OUT(DWIDTH)
    ) grayscale_0 (
        .clock(clock),
        .reset(reset),
        .fifo_in_rd_en(fifo_in_rd_en),
        .fifo_in_dout(fifo_in_dout),
        .fifo_in_empty(fifo_in_empty),
        .fifo_out_wr_en(fifo_wr_en[0]),
        .fifo_out_din(fifo_din[0]),
        .fifo_out_full(fifo_full[0])
    );

    if (USE_GAUSSIAN == 1'b1) begin
        op_padder #(
            .OP(0),
            .WINDOW_SIZE(5),
            .STRIDE(1),
            .DWIDTH_IN(DWIDTH),
            .DWIDTH_OUT(DWIDTH),
            .IMG_WIDTH(IMG_WIDTH),
            .IMG_HEIGHT(IMG_HEIGHT)
        ) gaussian_0 (
            .clock(clock),
            .reset(reset),
            .fifo_in_rd_en(fifo_rd_en[0]),
            .fifo_in_dout(fifo_dout[0]),
            .fifo_in_empty(fifo_empty[0]),
            .fifo_out_wr_en(fifo_wr_en[1]),
            .fifo_out_din(fifo_din[1]),
            .fifo_out_full(fifo_full[1])
        );
    end

    if (USE_SOBEL == 1'b1) begin
        op_padder #(
            .OP(1),
            .WINDOW_SIZE(3),
            .STRIDE(1),
            .DWIDTH_IN(DWIDTH),
            .DWIDTH_OUT(DWIDTH),
            .IMG_WIDTH(IMG_WIDTH),
            .IMG_HEIGHT(IMG_HEIGHT)
        ) sobel_0 (
            .clock(clock),
            .reset(reset),
            .fifo_in_rd_en(fifo_rd_en[0+USE_GAUSSIAN]),
            .fifo_in_dout(fifo_dout[0+USE_GAUSSIAN]),
            .fifo_in_empty(fifo_empty[0+USE_GAUSSIAN]),
            .fifo_out_wr_en(fifo_wr_en[1+USE_GAUSSIAN]),
            .fifo_out_din(fifo_din[1+USE_GAUSSIAN]),
            .fifo_out_full(fifo_full[1+USE_GAUSSIAN])
        );
    end

    genvar i;
    generate 
        for (i=0; i<NUM_FIFOS-1; i=i+1) begin 
            fifo #(
                .FIFO_DATA_WIDTH(DWIDTH),
                .FIFO_BUFFER_SIZE(BUFFER)
            ) fifos (
                .rd_clk(clock),
                .wr_clk(clock),
                .reset(reset),
                .wr_en(fifo_wr_en[i]),
                .din(fifo_din[i]),
                .full(fifo_full[i]),
                .rd_en(fifo_rd_en[i]),
                .dout(fifo_dout[i]),
                .empty(fifo_empty[i])
            );
        end
    endgenerate

endmodule
