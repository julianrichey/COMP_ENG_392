`timescale 1 ns / 1 ns

module gaussian_op #(
    parameter integer DWIDTH_IN = 8, //8*25 bits maybe???
    parameter integer DWIDTH_OUT = 8 //8 bits
) (
    input clock,
    input reset,

    input [DWIDTH_IN-1:0] in [0:24],
    output reg [DWIDTH_OUT-1:0] out
);


//summed up these all become 159?
    localparam signed [7:0] gauss_op [0:24] = {8'sh02, 8'sh04, 8'sh05, 8'sh04, 8'sh02, 8'sh04, 8'sh09, 8'sh0C, 8'sh09, 8'sh04, 8'sh05, 8'sh0C, 8'sh0E, 8'sh0C, 8'sh05, 8'sh04, 8'sh09, 8'sh0C, 8'sh09, 8'sh04, 8'sh02, 8'sh04, 8'sh05, 8'sh04, 8'sh02};
    //localparam signed [7:0] vert_op [0:24] = {8'shFF, 8'shFE, 8'shFF, 8'sh00, 8'sh00, 8'sh00, 8'sh01, 8'sh02, 8'sh01};

    reg signed [15:0] num, denom, v;

    function signed [15:0] abs;
        input [15:0] val;
        begin
            abs = (val < 0) ? -val : val;
        end
    endfunction

    integer i,j;
    always @* begin : gaussian_computation
        num = 16'h0000;
        denom = 16'h0000; //TO DO: SUM up all vals ant hard-code in the denom
        for (i=0; i<5; i=i+1) begin
            for (j=0; j<5; j=j+1) begin
                num = num + (in[i*5 + j] * gauss_op[j*5 + i]);
                denom = denom + gauss_op[j*5 + i];
            end
        end

        v = num / denom;
        out = (v > 16'sh00FF) ? 8'hFF : v[7:0];
    end


endmodule