`timescale 1 ns / 1 ns

`define CLOG2(x) \
    (x <= 2) ? 1 : \
    (x <= 4) ? 2 : \
    (x <= 8) ? 3 : \
    (x <= 16) ? 4 : \
    (x <= 32) ? 5 : \
    (x <= 64) ? 6 : \
    (x <= 128) ? 7 : \
    (x <= 256) ? 8 : \
    (x <= 512) ? 9 : \
    (x <= 1024) ? 10 : \
    (x <= 2048) ? 11 : \
    (x <= 4096) ? 12 : \
    -1

module fifo #(
    parameter FIFO_BUFFER_SIZE = 0,
    parameter FIFO_DATA_WIDTH = 0
) (
    input reset,

    input wr_clk,
    input wr_en,
    input [FIFO_DATA_WIDTH-1:0] din,
    output reg full,

    input rd_clk,
    input rd_en,
    output reg [FIFO_DATA_WIDTH-1:0] dout,
    output reg empty
);
    //{} for +1 overflow (e.g. depth=8)
    localparam idx_width = {1'b0, `CLOG2(FIFO_BUFFER_SIZE)} + 1;

    reg [FIFO_DATA_WIDTH-1:0] q [FIFO_BUFFER_SIZE-1:0];
    reg [idx_width-1:0] wr_idx;
    reg [idx_width-1:0] rd_idx;

    assign dout = q[rd_idx[idx_width-2:0]];
    assign empty = wr_idx == rd_idx;
    assign full = (wr_idx[idx_width-1] != rd_idx[idx_width-1]) && 
                  (wr_idx[idx_width-2:0] == rd_idx[idx_width-2:0]);

    integer i;
    always @(posedge wr_clk) begin
        if (reset) begin
            wr_idx <= 0;
            for (i=0; i<FIFO_BUFFER_SIZE; i=i+1) q[i] <= 0;
        end else if (wr_en) begin
            q[wr_idx[idx_width-2:0]] <= din;
            wr_idx <= wr_idx + 1;
        end
    end

    always @(posedge rd_clk) begin
        if (reset) begin
            rd_idx <= 0;
        end else if (rd_en) begin
            rd_idx <= rd_idx + 1;
        end
    end
endmodule

