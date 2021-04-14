
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

    localparam integer S0 = 2'h0, S1 = 2'h1;
    reg [1:0] state, next_state;

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
    
    
    //This is the simplest possible test case for dut.v, but output 
    //  still black (ie all 0s)
    /*
    always @* begin
        fifo_in_rd_en = 1'b1;
        fifo_out_wr_en = 1'b1;
        fifo_out_din = 24'h555555;
    end
    */


    /*
    always @(posedge clock, posedge reset) begin
        if (reset) begin
            fifo_in_rd_en <= 1'b0;
            fifo_out_wr_en <= 1'b0;
            fifo_out_din <= 'b0;
        end else begin
            data <= data_c;
        end
    end

    //NOTE: 24'h555555 is a temporary value that should display gray. 
    //  Currently, black is shown regardless of this value, meaning 
    //  there's a bug somewhere after this. 
    always @* begin
        data_c = data;
        fifo_in_rd_en = 1'b0;
        fifo_out_wr_en = 1'b0;
        fifo_out_din = 24'h555555;//data;

        if (fifo_in_empty == 1'b0) begin
            fifo_in_rd_en = 1'b1;
            data_c = 24'h555555;//rgb_avg(fifo_in_dout);
        end

        if (fifo_out_full == 1'b0) begin
            fifo_out_wr_en = 1'b1;
        end
    end
    */

    
    always @ (posedge clock, posedge reset)
    begin : clocked_process
        if ( reset == 1'b1 ) begin
            state <= S0;
            data <= 0;
        end
        else if ( clock == 1'b1 ) begin
            state <= next_state;
            data <= data_c;
        end
    end

    always @ ( * )
    begin : fsm_process
        next_state <= state;
        data_c <= data;
        fifo_in_rd_en <= 1'b0;
        fifo_out_wr_en <= 1'b0;
        fifo_out_din <= data;

        case(state) 
            S0: begin
                if ( fifo_in_empty == 1'b0 ) begin
                    //HERE IS WHERE WE WOULD CALCULATE THE GRAYSCALE
                    data_c <= fifo_in_dout;
                    fifo_in_rd_en <= 1'b1;
                    next_state <= S1;
                end
            end

            S1: begin
                if ( fifo_out_full == 1'b0 ) begin
                    fifo_out_wr_en <= 1'b1;
                    next_state <= S0;
                end                
            end

            default : begin
                next_state <= S0;
            end
        endcase
    end
    

endmodule
