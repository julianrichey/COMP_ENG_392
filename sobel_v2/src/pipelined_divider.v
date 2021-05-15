// pipelined_divider
// Divides signed dividend by unsigned divisor.
// Parameterized to take in inputs of variable size.
// Combines remainder and quotient registers, shifting both at once. 

//todo: give this a reset input, add reset condition to all blocks

`timescale 1ns/1ns

//numerator = dividend, denominator = divisor
module pipelined_divider (
    input                             clock,

    input                             input_valid,
    input      [dividend_width - 1:0] dividend,
    input       [divisor_width - 1:0] divisor,

    output reg                        output_valid,
    output reg [dividend_width - 1:0] quotient,
    output reg [dividend_width - 1:0] remainder
);
    
    parameter integer dividend_width = 12
    parameter integer divisor_width = 6;
    localparam integer stages = dividend_width; 
    localparam rem_width = dividend_width + divisor_width;
    parameter round = 1'b1; //if 1, round quotient to nearest integer. if 0, floor quotient.

    reg [divisor_width - 1:0] divisors   [0:stages];
    reg [rem_width - 1:0]     remainders [0:stages];
    reg neg_flags [0:stages]; //set if dividend is negative
    reg stage_valid [0:stages];

    always @(posedge clock) begin
        if (dividend[dividend_width - 1] == 1'b1) begin
            neg_flags[0] <= 1'b1;
            remainders[0] <= {{divisor_width{1'b0}}, -dividend}; //MSB of dividend is 0 bc positive, so divisor_width+1 0s
        end else begin
            neg_flags[0] <= 1'b0;
            remainders[0] <= {{divisor_width{1'b0}}, dividend};
        end
        divisors[0] <= divisor;

        stage_valid[0] <= input_valid;
    end

    genvar i;
    generate
        for (i = 0; i < stages; i = i + 1) begin
            always @(posedge clock) begin
                //no underflow/positive
                if (remainders[i][rem_width - 1:dividend_width - 1] - {1'b0, divisors[i]} <= remainders[i][rem_width - 1:dividend_width - 1]) begin
                    remainders[i + 1] <= ({remainders[i][rem_width - 1:dividend_width - 1] - {1'b0, divisors[i]}, remainders[i][dividend_width - 2:0]} << 1) | 1;
                //underflow/negative
                end else begin
                    remainders[i + 1] <= remainders[i] << 1;
                end
                divisors[i + 1] <= divisors[i];
                neg_flags[i + 1] <= neg_flags[i];

                stage_valid[i + 1] <= stage_valid[i];
            end
        end
    endgenerate

    always @(posedge clock) begin
        if (neg_flags[stages]) begin
            if (round && ({1'b0, remainders[stages][rem_width - 1:dividend_width]} << 1 >= divisors[stages])) begin
                quotient <= -remainders[stages][dividend_width - 1:0] - 1'b1;
            end else begin
                quotient <= -remainders[stages][dividend_width - 1:0];
            end
            remainder <= -remainders[stages][rem_width - 1:dividend_width];
        end else begin
            if (round && ({1'b0, remainders[stages][rem_width - 1:dividend_width]} << 1 >= divisors[stages])) begin
                quotient <= remainders[stages][dividend_width - 1:0] + 1'b1;
            end else begin
                quotient <= remainders[stages][dividend_width - 1:0];
            end
            remainder <= remainders[stages][rem_width - 1:dividend_width];
        end

        output_valid <= stage_valid[stages];
    end 
endmodule
