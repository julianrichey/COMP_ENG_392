`timescale 1 ns / 1 ns

module op_gaussian #(
    parameter integer DWIDTH_IN = 8*5*5,
    parameter integer DWIDTH_OUT = 8
) (
    input clock,
    input reset,

    input [DWIDTH_IN-1:0] in,
    output reg [DWIDTH_OUT-1:0] out
);
    localparam [7:0] gauss_op [0:24] = '{8'h02, 8'h04, 8'h05, 8'h04, 8'h02, 8'h04, 8'h09, 8'h0C, 8'h09, 8'h04, 8'h05, 8'h0C, 8'h0E, 8'h0C, 8'h05, 8'h04, 8'h09, 8'h0C, 8'h09, 8'h04, 8'h02, 8'h04, 8'h05, 8'h04, 8'h02};
    localparam [7:0] denom = 8'b10011111; //159

    //max numerator calculation:
    //0b1001_1110_0110_0001 = 2*0b11111111 + 4*0b11111111 + 5*0b11111111 + 4*0b11111111 + 2*0b11111111 + 4*0b11111111 + 9*0b11111111 + 12*0b11111111 + 9*0b11111111 + 4*0b11111111 + 5*0b11111111 + 12*0b11111111 + 15*0b11111111 + 12*0b11111111 + 5*0b11111111 + 4*0b11111111 + 9*0b11111111 + 12*0b11111111 + 9*0b11111111 + 4*0b11111111 + 2*0b11111111 + 4*0b11111111 + 5*0b11111111 + 4*0b11111111 + 2*0b11111111
    //num is good at 16 bits because >0

    reg [15:0] num, v;
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
        for (i=0; i<5; i=i+1) begin
            for (j=0; j<5; j=j+1) begin
                num = num + ({8'h00,in[i*5 + j]} * {8'h00,gauss_op[j*5 + i]});
            end
        end

        v = num / denom;
        out_c = (v > 16'h00FF) ? 8'hFF : v[7:0];
    end


endmodule