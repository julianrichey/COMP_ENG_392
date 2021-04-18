/*
thoughts:
two general ways of going about this
1. every stage, put output into memory
    doesn't this defeat the purpose of using fifos???
    rgb starts in memory
    some number of grayscale modules go through each pixel, put in fifos????, then write all this to memory
    sobel goes through each pixel, reading all pixels from memory multiple times
        maybe with some crazy structure each pixel could be read only once... would take some thought
2. every stage, put output info fifo that feeds directly into next stage
    each sobel needs 9 pixels coming in at all times
        turns out, this can be 3 small shift registers
        example sobel: input pixels 1,2,3,721,722,723,1441,1442,1443
        the next sobel computation: input pixels 2,3,4,722,723,724,1442,1443,1444
        shift registers: [1,2,3]<-4 ; [721,722,723]<-724 ; [1441,1442,1443]<-1444
    each sobel reuses 6 pixels, so each needs only 3 instantiations of grayscale
    BUT, if there are 540 sobels, these grayscales can be reused, so only 540 grayscale needed total
        the /3 might take up enough LUTs to make this worthwhile, if there are enough FFs/LUTs to have 540 sobels (highly doubtful)
    vertically adjacent sobels reuse data coming from grayscales
    so, there will be an optimal number of sobels. if 270 are used, 1 row of pixels gets fetched from memory twice. if 135, 3. etc
*/


/*
current architecture

rgb fifo - width=96
3 grayscales
grayscale fifo - width=24
1 sobel
sobel fifo - width=8


NOTE: fifo_in_din is expanded. If 1 sobel needs 3 new grayscale pixels each cycle, this needs to triple in width. 
e.g. pixels 1,721,1441 from testbench at same time in fifo_in_din[23:0], fifo_in_din[47:24], fifo_in_din[71:48]

*/

`timescale 1 ns / 1 ns

module dut_system #(
    parameter integer NUM_SOBELS,
    parameter integer NUM_GRAYSCALES,
    parameter integer RGB_BUFFER,
    parameter integer RGB_DWIDTH,
    parameter integer GRAYSCALE_BUFFER,
    parameter integer GRAYSCALE_DWIDTH,
    parameter integer SOBEL_BUFFER,
    parameter integer SOBEL_DWIDTH
) (
    input clock,
    input reset,

    input fifo_in_wr_en, //write to first fifos
    input [RGB_DWIDTH-1:0] fifo_in_din, //data to all first fifos
    output fifo_in_full,

    input fifo_out_rd_en,
    output [SOBEL_DWIDTH-1:0] fifo_out_dout,
    output fifo_out_empty
);


    wire [NUM_] fifo_in_wr_en;
    input  wire [RGB_DWIDTH-1:0] fifo_in_din;
    output wire fifo_in_full;

    // output fifo
    input  wire fifo_out_rd_en;
    output wire [(SOBEL_DWIDTH - 1):0] fifo_out_dout;
    output wire fifo_out_empty;




    // local input fifo wires
    wire fifo_in_rd_en;
    wire [(FIFO_DWIDTH_IN - 1):0] fifo_in_dout;
    wire fifo_in_empty;

    // local output fifo wires
    wire fifo_out_wr_en;
    wire [(FIFO_DWIDTH_OUT - 1):0] fifo_out_din;
    wire fifo_out_full;


    sobel #(
        .
        .
        .
        .
    ) sobel_0 (

    );

    /*
    genvar i;
    generate
        for (i=0; i<NUM_GRAYSCALES; i=i+1) begin : generate_grayscales
            grayscale #(

            ) grayscale_inst (

            );
        end
    endgenerate
    */

    //I believe this syntax is identical to a generate?!
    grayscale #(
        .CONVERT_GRAYSCALE(CONVERT_GRAYSCALE),
        .FIFO_DWIDTH_IN(FIFO_DWIDTH_IN),
        .FIFO_DWIDTH_OUT(FIFO_DWIDTH_OUT)
    ) grayscales[NUM_GRAYSCALES-1:0] (
        .clock(clock),
        .reset(reset),
        .fifo_in_rd_en(fifo_in_rd_en),
        .fifo_in_dout(fifo_in_dout),
        .fifo_in_empty(fifo_in_empty),
        .fifo_out_wr_en(fifo_out_wr_en),
        .fifo_out_din(fifo_out_din),
        .fifo_out_full(fifo_out_full)
    );




    fifo #(
        .FIFO_DATA_WIDTH(FIFO_DWIDTH_IN),
        .FIFO_BUFFER_SIZE(FIFO_BUFFER_SIZE)
    ) fifo_rgb (
        .rd_clk(clock),
        .wr_clk(clock),
        .reset(reset),
        .rd_en(fifo_in_rd_en),
        .wr_en(fifo_in_wr_en),
        .din(fifo_in_din),
        .dout(fifo_in_dout),
        .full(fifo_in_full),
        .empty(fifo_in_empty)
    );

    fifo #(
        .FIFO_DATA_WIDTH(FIFO_DWIDTH_OUT),
        .FIFO_BUFFER_SIZE(FIFO_BUFFER_SIZE)
    ) fifo_grayscale (
        .rd_clk(clock),
        .wr_clk(clock),
        .reset(reset),
        .rd_en(fifo_out_rd_en),
        .wr_en(fifo_out_wr_en),
        .din(fifo_out_din),
        .dout(fifo_out_dout),
        .full(fifo_out_full),
        .empty(fifo_out_empty)
    );

    fifo #(
        .FIFO_DATA_WIDTH(FIFO_DWIDTH_OUT),
        .FIFO_BUFFER_SIZE(FIFO_BUFFER_SIZE)
    ) fifo_sobel (
        .rd_clk(clock),
        .wr_clk(clock),
        .reset(reset),
        .rd_en(fifo_out_rd_en),
        .wr_en(fifo_out_wr_en),
        .din(fifo_out_din),
        .dout(fifo_out_dout),
        .full(fifo_out_full),
        .empty(fifo_out_empty)
    );



endmodule
