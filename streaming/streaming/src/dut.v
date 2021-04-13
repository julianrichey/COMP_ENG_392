
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

    localparam integer S0 = 2'h0, S1 = 2'h1;
    reg [1:0] state, next_state;
    reg [(FIFO_DATA_WIDTH - 1):0] data, data_c;

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
