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

module op_sobel #(
    parameter integer DWIDTH_IN = 8*3*3,
    parameter integer DWIDTH_OUT = 8,
    parameter integer IMG_WIDTH,
    parameter integer IMG_HEIGHT
) (
    input clock,
    input reset,
    input [`CLOG2(IMG_WIDTH + 3)-1:0] x,
    input [`CLOG2(IMG_HEIGHT + 3)-1:0] y,
    input [DWIDTH_IN-1:0] in,
    output reg [DWIDTH_OUT-1:0] out
);
    localparam [7:0] horiz_op [0:8] = '{8'hFF, 8'h00, 8'h01, 8'hFE, 8'h00, 8'h02, 8'hFF, 8'h00, 8'h01};
    localparam [7:0] vert_op [0:8] = '{8'hFF, 8'hFE, 8'hFF, 8'h00, 8'h00, 8'h00, 8'h01, 8'h02, 8'h01};

    reg [15:0] hor_grad, vert_grad, v;
    reg [DWIDTH_OUT-1:0] out_c;

    reg [7:0] data [0:DWIDTH_IN/8-1];

    function [15:0] abs;
        input [15:0] val;
        begin
            abs = (val[15] == 1'b1) ? -val : val;
        end
    endfunction

    // maps in (72 bits) to data (9 array of 8 bits)
    integer a;
    always @* begin
        for (a=0; a<DWIDTH_IN/8; a=a+1) begin
            data[a] = in[a*8 +: 8];
        end
    end

    always @(posedge clock) begin
        if (reset == 1'b1) begin
            out <= 'h0;
        end else begin
            out <= out_c;
        end
    end

    integer i,j;
    always @* begin : sobel_computation
        hor_grad = 16'h0000;
        vert_grad = 16'h0000;
        for (i=0; i<3; i=i+1) begin
            for (j=0; j<3; j=j+1) begin
                hor_grad = hor_grad + ($signed({8'h00,data[i*3 + j]}) * $signed({{8{horiz_op[j*3 + i][7]}},horiz_op[j*3 + i]}));
                vert_grad = vert_grad + ($signed({8'h00,data[i*3 + j]}) * $signed({{8{vert_op[j*3 + i][7]}},vert_op[j*3 + i]}));
            end
        end

        v = (abs(hor_grad) + abs(vert_grad)) >> 1;

        //sobel outputs black for edges
        if (x > 2 && x < IMG_WIDTH && y > 1 && y < IMG_HEIGHT) begin
            out_c = (v > 16'h00FF) ? 8'hFF : v[7:0];
        end else begin
            out_c = 'b0;
        end

    end
endmodule
