`timescale 1 ns / 1 ns

module sobel_op #(
    parameter integer DWIDTH_IN = 72, //8*9 bits
    parameter integer DWIDTH_OUT = 8 //8 bits
) (
    input wire clock,
    input wire reset,

    input wire [DWIDTH_IN-1:0] in,
    output reg [DWIDTH_OUT-1:0] out
);
    localparam signed [7:0] horiz_op [0:8] = '{8'shFF, 8'sh00, 8'sh01, 8'shFE, 8'sh00, 8'sh02, 8'shFF, 8'sh00, 8'sh01};
    localparam signed [7:0] vert_op [0:8] = '{8'shFF, 8'shFE, 8'shFF, 8'sh00, 8'sh00, 8'sh00, 8'sh01, 8'sh02, 8'sh01};

    reg signed [15:0] hor_grad, vert_grad, v;
    reg [DWIDTH_OUT-1:0] out_c;

    reg signed [7:0] data [0:DWIDTH_IN/8-1];

    function signed [15:0] abs;
        input [15:0] val;
        begin
            abs = (val < 0) ? -val : val;
        end
    endfunction

    always @(posedge clock, posedge reset) begin
        if (reset == 1'b1) begin
            out <= 'h0;
        end else if (clock == 1'b1) begin
            out <= out_c;
        end
    end

    //maps in (72 bits) to data (9 array of 8 bits)
    integer a;
    always @* begin
        for (a=0; a<DWIDTH_IN/8; a=a+1) begin
            data[a] = in[a*8 +: 8];
        end
    end

    integer i,j;
    always @* begin : sobel_computation
        hor_grad = 16'h0000;
        vert_grad = 16'h0000;
        for (i=0; i<3; i=i+1) begin
            for (j=0; j<3; j=j+1) begin
                hor_grad = hor_grad + (data[i*3 + j] * horiz_op[j*3 + i]);
                vert_grad = vert_grad + (data[i*3 + j] * vert_op[j*3 + i]);
            end
        end

        v = signed'(abs(hor_grad) + abs(vert_grad)) >>> 1;
        out_c = (v > 16'sh00FF) ? 8'hFF : v[7:0];
    end
endmodule