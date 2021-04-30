//unclocked function vs clocked out??

`timescale 1 ns / 1 ns

module sobel_op #(
    parameter integer DWIDTH_IN = 72, //8*9 bits
    parameter integer DWIDTH_OUT = 8 //8 bits
) (
    input clock,
    input reset,

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

    always @(posedge clock) begin
        if (reset == 1'b1) begin
            out <= 'h0;
        end else begin
            out <= out_c;
        end
    end

    // maps in (72 bits) to data (9 array of 8 bits)
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
                hor_grad = hor_grad + ($signed({{8{data[i*3 + j][7]}},data[i*3 + j]}) * $signed({{8{horiz_op[j*3 + i][7]}},horiz_op[j*3 + i]}));
                vert_grad = vert_grad + ($signed({{8{data[i*3 + j][7]}},data[i*3 + j]}) * $signed({{8{vert_op[j*3 + i][7]}},vert_op[j*3 + i]}));
            end
        end

        v = (abs(hor_grad) + abs(vert_grad)) >> 1;
        out_c = (v > 255) ? 255 : v[7:0];
        // out_c = ({4'h0,in[71:64]} + {4'h0,in[63:56]} + {4'h0,in[55:48]} + {4'h0,in[47:40]} + {4'h0,in[39:32]} + {4'h0,in[31:24]} + {4'h0,in[23:16]} + {4'h0,in[15:8]} + {4'h0,in[7:0]}) / 9;
        // out_c = data[4];
    end
endmodule

// 210
// 543
// 876
