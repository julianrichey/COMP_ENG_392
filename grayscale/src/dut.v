
`timescale 1 ns / 1 ns

module dut(clock, reset, fifo_in_rd_en, fifo_in_dout, fifo_in_empty, fifo_out_wr_en, fifo_out_din, fifo_out_full);

    parameter integer FIFO_DATA_WIDTH = 32;

    input wire clock;
    input wire reset;

    // input fifo
    output reg fifo_in_rd_en;
    input  wire [(FIFO_DATA_WIDTH - 1):0] fifo_in_dout;
    input  wire fifo_in_empty;

    // output fifo
    output reg fifo_out_wr_en;
    output reg [(FIFO_DATA_WIDTH - 1):0] fifo_out_din;
    input  wire fifo_out_full;

    reg [FIFO_DATA_WIDTH-1:0] data, data_c;
    reg is_data, is_data_c;

    function [23:0] rgb_avg;
        input [23:0] vals;
        reg [9:0] sum;
        reg [7:0] result;
        begin
			sum = vals[23:16] + vals[15:8] + vals[7:0];
            //may or may not fly in hardware
            //if not, x/3 = x * 1/3; 1/3 = 0.0101010101 in base 2
            //http://homepage.divms.uiowa.edu/~jones/bcd/divide.html
			result = sum / 3;
            rgb_avg = {3{result}};
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
