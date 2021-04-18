
`timescale 1 ns / 1 ns

module grayscale #(
    parameter integer DWIDTH_IN,
    parameter integer DWIDTH_OUT
) (
    input clock,
    input reset,

    //fifo in
    output reg fifo_in_rd_en, 
    input [FIFO_DWIDTH_IN-1:0] fifo_in_dout, 
    input fifo_in_empty,

    //fifo out
    output reg fifo_out_wr_en, 
    output reg [DWIDTH_OUT-1:0] fifo_out_din, 
    input fifo_out_full
);

    reg [DWIDTH_OUT-1:0] data, data_c;
    reg is_data, is_data_c;

    function [7:0] rgb_avg;
        input [23:0] vals;
        reg [9:0] sum;
        begin
            sum = vals[23:16] + vals[15:8] + vals[7:0];
            //may or may not fly in hardware
            //if not, x/3 = x * 1/3; 1/3 = 0.0101010101 in base 2
            //http://homepage.divms.uiowa.edu/~jones/bcd/divide.html
            rgb_avg = sum / 3;
        end
    endfunction
    
    always @(posedge clock, posedge reset) begin
        if (reset) begin
            fifo_in_rd_en <= 1'b0;
            fifo_out_wr_en <= 1'b0;
            fifo_out_din <= 'b0;
            is_data <= 1'b0;
        end else begin
            data <= data_c;
            is_data <= is_data_c;
        end
    end

    always @* begin
        data_c = data;
        fifo_in_rd_en = 1'b0;
        fifo_out_wr_en = 1'b0;
        fifo_out_din = data;
        is_data_c = 1'b0;

        if (fifo_in_empty == 1'b0) begin
            is_data_c = 1'b1;
            fifo_in_rd_en = 1'b1;
            data_c = rgb_avg(fifo_in_dout);
        end

        if (fifo_out_full == 1'b0 && is_data == 1'b1) begin
            fifo_out_wr_en = 1'b1;
        end
    end

endmodule
