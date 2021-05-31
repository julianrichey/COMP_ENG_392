`timescale 1 ns / 1 ns

module bram #(
    parameter integer BRAM_BUFFER_SIZE = 388800, //720*540
    parameter integer BRAM_DATA_WIDTH = 12,
    parameter integer BRAM_ADDR_WIDTH = 19 //log2(388800) = 18.6 
) (
    input reset,
    input clock,
    input [BRAM_ADDR_WIDTH - 1 : 0] rd_addr,
    input [BRAM_ADDR_WIDTH - 1 : 0] wr_addr,
    input wr_en,
    input [BRAM_DATA_WIDTH - 1 : 0] din,
    output [BRAM_DATA_WIDTH - 1 : 0] dout
);
    //reg [BRAM_ADDR_WIDTH - 1 : 0] rd_addr_clocked;
    reg [BRAM_DATA_WIDTH-1:0] mem [0:BRAM_BUFFER_SIZE-1];

    assign dout = mem[rd_addr];
    integer i;
    always @(posedge clock) begin
        if (reset == 1'b1) begin
            //rd_addr_clocked = 'b0;
            //assign mem all 0's 
            for (i = 0; i < BRAM_BUFFER_SIZE; i=i+1) begin
                mem[i] = 'b0;
            end
        end else begin
            //rd_addr_clocked = rd_addr;
            if(wr_en == 1'b1) begin
                mem[wr_addr] = din;
            end
        end
    end
endmodule