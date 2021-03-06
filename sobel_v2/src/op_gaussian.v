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
    input [`CLOG2(IMG_WIDTH + 5)-1:0] x,
    input [`CLOG2(IMG_HEIGHT + 5)-1:0] y,
    input [DWIDTH_IN-1:0] in,
    output reg [DWIDTH_OUT-1:0] out
);
    localparam [7:0] gauss_op [0:24] = '{8'h02, 8'h04, 8'h05, 8'h04, 8'h02, 
                                         8'h04, 8'h09, 8'h0C, 8'h09, 8'h04, 
                                         8'h05, 8'h0C, 8'h0F, 8'h0C, 8'h05, 
                                         8'h04, 8'h09, 8'h0C, 8'h09, 8'h04, 
                                         8'h02, 8'h04, 8'h05, 8'h04, 8'h02};

    //max numerator calculation:
    //0b1001_1110_0110_0001 = 2*0b11111111 + 4*0b11111111 + 5*0b11111111 + 4*0b11111111 + 2*0b11111111 + 
    //                        4*0b11111111 + 9*0b11111111 + 12*0b11111111 + 9*0b11111111 + 4*0b11111111 + 
    //                        5*0b11111111 + 12*0b11111111 + 15*0b11111111 + 12*0b11111111 + 5*0b11111111 + 
    //                        4*0b11111111 + 9*0b11111111 + 12*0b11111111 + 9*0b11111111 + 4*0b11111111 + 
    //                        2*0b11111111 + 4*0b11111111 + 5*0b11111111 + 4*0b11111111 + 2*0b11111111
    //num is good at 16 bits because >0

    //max denominator = 0b10011111, denom is good at 8 bits

    reg [15:0] num;
    reg [7:0] denom;
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
            //04x
            //pg 279- format specifications
            //u in verilog refers to something else
            //$write("%d,%d:   Numerator: %d    Denominator: %d    Result: %d  \n", y-2, x-2, num, denom, out_c);
        end
    end

    integer i,j;
    always @* begin : gaussian_computation
        num = 16'h0000;
        denom = 16'h0000;
        for (j=0; j<5; j=j+1) begin
            for (i=0; i<5; i=i+1) begin
                if (
                    x + i >= 4 &&
                    x + i < IMG_WIDTH + 4 &&
                    y + j >= 4 &&
                    y + j < IMG_HEIGHT + 4
                ) begin
                    num = num + ({8'h00,data[(4-j)*5 + (4-i)]} * {8'h00,gauss_op[(i)*5 + (j)]});
                    denom = denom + {8'h00,gauss_op[(i)*5 + (j)]};
                end
            end
        end

        //
        //out_c = num / denom;    
    end

    wire [16:0] num_extend;
    assign num_extend = {1'b0, num};

    wire reset_n;
    assign reset_n = ~reset;

    wire output_valid;
    wire [16:0] remainder_extend;
    wire [16:0] quotient_extend;
    assign out_c = quotient_extend[7:0];

    pipelined_divider #( //Divides signed dividend by unsigned divisor
        .dividend_width(17), //dividend width is ~ the # cycles for a division to happen
        .divisor_width(8),
        .round(1'b0)
    ) pipelined_divider_0 (
        .clock(clock),
        .reset(reset),
        .input_valid(reset_n), //assume that there is valid input any non-reset cycle
        .dividend(num_extend),
        .divisor(denom),
        .output_valid(output_valid), //should probably use this? but instead just count cycles
        .quotient(quotient_extend),
        .remainder(remainder_extend)
    );

endmodule
