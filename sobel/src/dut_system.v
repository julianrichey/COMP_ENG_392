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

    //rgb fifo to grayscales
    wire fifo_rgb_rd_en;
    wire [RGB_DWIDTH-1:0] fifo_rgb_dout;
    wire fifo_rgb_empty;

    //grayscales to grayscale fifo
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

    //when multiple modules instantiated, they can't write to the same wire
    wire [NUM_GRAYSCALES-1:0] fifo_rgb_rd_en_arr;
    wire [NUM_GRAYSCALES-1:0] fifo_grayscale_wr_en_arr;
    //wire [NUM_SOBELS-1:0] fifo_sobel_rd_en_arr; //right now, just grayscales- deal with sobels later
    //wire [NUM_SOBELS-1:0] fifo_sobel_wr_en_arr;
    
    //these should have the same behavior, so just reduce their wires when it would be a problem (OR or AND, shouldn't matter)
    assign fifo_rgb_rd_en = |fifo_rgb_rd_en_arr;
    assign fifo_grayscale_wr_en = |fifo_grayscale_wr_en_arr;





    sobel #(
        .DWIDTH_IN(GRAYSCALE_DWIDTH),
        .DWIDTH_OUT(SOBEL_DWIDTH)
    ) sobels (
        .clock(clock),
        .reset(reset),
        .fifo_in_rd_en(fifo_grayscale_rd_en), //(will be >1 sobels vs 1 fifo)
        .fifo_in_dout(fifo_grayscale_dout),
        .fifo_in_empty(fifo_grayscale_empty),
        .fifo_out_wr_en(fifo_sobel_wr_en), //(will be >1 sobels vs 1 fifo)
        .fifo_out_din(fifo_sobel_din),
        .fifo_out_full(fifo_sobel_full)
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

    //for this syntax:
    //when a connected wire is the same width as is defined in the module definition, the same wire is connected to all instances
    //when a connected wire is a different width than is defined in the module definition, the indices will be spread out evenly across all instances

    grayscale #(
        .DWIDTH_IN(RGB_DWIDTH),
        .DWIDTH_OUT(GRAYSCALE_DWIDTH)
    ) grayscales[NUM_GRAYSCALES-1:0] (
        .clock(clock),
        .reset(reset),
        .fifo_in_rd_en(fifo_rgb_rd_en_arr), //>1 grayscales vs 1 fifo
        .fifo_in_dout(fifo_rgb_dout),
        .fifo_in_empty(fifo_rgb_empty),
        .fifo_out_wr_en(fifo_grayscale_wr_en_arr), //>1 grayscales vs 1 fifo
        .fifo_out_din(fifo_grayscale_din),
        .fifo_out_full(fifo_grayscale_full)
    );

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
