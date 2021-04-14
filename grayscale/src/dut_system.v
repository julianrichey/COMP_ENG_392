
`timescale 1 ns / 1 ns

module dut_system(clock, reset, fifo_in_wr_en, fifo_in_din, fifo_in_full, fifo_out_empty, fifo_out_rd_en, fifo_out_dout);

    parameter integer FIFO_DATA_WIDTH = 32;
    parameter integer FIFO_BUFFER_SIZE = 64;

    input wire clock;
    input wire reset;

    // input fifo
    input  wire fifo_in_wr_en;
    input  wire [(FIFO_DATA_WIDTH - 1):0] fifo_in_din;
    output wire fifo_in_full;

    // output fifo
    input  wire fifo_out_rd_en;
    output wire [(FIFO_DATA_WIDTH - 1):0] fifo_out_dout;
    output wire fifo_out_empty;

    // local input fifo wires
    wire fifo_in_rd_en;
    wire [(FIFO_DATA_WIDTH - 1):0] fifo_in_dout;
    wire fifo_in_empty;

    // local output fifo wires
    wire fifo_out_wr_en;
    wire [(FIFO_DATA_WIDTH - 1):0] fifo_out_din;
    wire fifo_out_full;


    fifo
    #(.FIFO_DATA_WIDTH(FIFO_DATA_WIDTH),
      .FIFO_BUFFER_SIZE(FIFO_BUFFER_SIZE))
    fifo_in_inst
    (
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

    fifo
    #(.FIFO_DATA_WIDTH(FIFO_DATA_WIDTH),
      .FIFO_BUFFER_SIZE(FIFO_BUFFER_SIZE))
    fifo_out_inst
    (
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

	dut
    #(.FIFO_DATA_WIDTH(FIFO_DATA_WIDTH))    
	dut_inst
	(
		.clock(clock), 
        .reset(reset), 
        .fifo_in_rd_en(fifo_in_rd_en), 
        .fifo_in_dout(fifo_in_dout),
        .fifo_in_empty(fifo_in_empty), 
        .fifo_out_wr_en(fifo_out_wr_en), 
        .fifo_out_din(fifo_out_din), 
        .fifo_out_full(fifo_out_full)
	);
    
endmodule
