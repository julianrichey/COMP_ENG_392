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

module op_gaussian #(
    parameter integer DWIDTH_IN = 8*5*5,
    parameter integer DWIDTH_OUT = 8,

    parameter integer IMG_WIDTH,
    parameter integer IMG_HEIGHT
) (
    input clock,
    input reset,

    input [`CLOG2(IMG_WIDTH)-1:0] x, //warnings about port size???
    input [`CLOG2(IMG_HEIGHT)-1:0] y,

    input [DWIDTH_IN-1:0] in,
    output reg [DWIDTH_OUT-1:0] out
);
    localparam [7:0] gauss_op [0:24] = '{8'h02, 8'h04, 8'h05, 8'h04, 8'h02, 8'h04, 8'h09, 8'h0C, 8'h09, 8'h04, 8'h05, 8'h0C, 8'h0E, 8'h0C, 8'h05, 8'h04, 8'h09, 8'h0C, 8'h09, 8'h04, 8'h02, 8'h04, 8'h05, 8'h04, 8'h02};
    //localparam [7:0] denom = 8'b10011111; //159

    //max numerator calculation:
    //0b1001_1110_0110_0001 = 2*0b11111111 + 4*0b11111111 + 5*0b11111111 + 4*0b11111111 + 2*0b11111111 + 4*0b11111111 + 9*0b11111111 + 12*0b11111111 + 9*0b11111111 + 4*0b11111111 + 5*0b11111111 + 12*0b11111111 + 15*0b11111111 + 12*0b11111111 + 5*0b11111111 + 4*0b11111111 + 9*0b11111111 + 12*0b11111111 + 9*0b11111111 + 4*0b11111111 + 2*0b11111111 + 4*0b11111111 + 5*0b11111111 + 4*0b11111111 + 2*0b11111111
    //num is good at 16 bits because >0

    reg [15:0] num, denom, v;
    reg [DWIDTH_OUT-1:0] out_c;

    reg [7:0] data [0:DWIDTH_IN/8-1];

    // maps in (200 bits) to data (25 array of 8 bits)
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
    always @* begin : gaussian_computation
        num = 16'h0000;
        denom = 16'h0000;
        for (i=-2; i<2; i=i+1) begin
            for (j=-2; j<2; j=j+1) begin
                //need to be signed comparisons
                if (($signed({2'b00,x}) + i) >= 0 && ({1'b0,x}+i) < IMG_WIDTH && ($signed({2'b00,y})+j) >= 0 && ({1'b0,y}+j) < IMG_HEIGHT) begin
                    num = num + ({8'h00,data[(i+2)*5 + (j+2)]} * {8'h00,gauss_op[(j+2)*5 + (i+2)]});
                    denom = denom + {8'h00,gauss_op[(j+2)*5 + (i+2)]};
                end
            end
        end

        out_c = num / denom;
        //out_c = (v > 16'h00FF) ? 8'hFF : v[7:0];
        // out_c = data[12];
    end


endmodule