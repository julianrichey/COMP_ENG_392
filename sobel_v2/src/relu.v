`timescale 1 ns / 1 ns

module relu #(
    parameter integer DWIDTH_IN,
    parameter integer DWIDTH_OUT
) (
    input clock,
    input reset,

    output reg fifo_in_rd_en,
    //HERE: Assume that data we pass into RELU is signed
    input signed [DWIDTH_IN-1:0] fifo_in_dout,
    input fifo_in_empty,

    output reg fifo_out_wr_en, 
    output reg signed [DWIDTH_OUT-1:0] fifo_out_din, 
    input fifo_out_full
);
    reg [DWIDTH_OUT-1:0] fifo_out_din_c;
    reg fifo_out_wr_en_c;

//assume that data is in 2's complement
    function signed [7:0] RELU;
        input signed[7:0] vals;
        //reg [7:0] sum;
        begin

            if(vals < 0) begin
                RELU = 'b0;
            end
            else begin
                RELU = vals;
            end

        end
    endfunction

    always @(posedge clock) begin
        if (reset == 1'b1) begin
            fifo_out_din <= 'b0;
            fifo_out_wr_en <= 1'b0;
        end else begin
            fifo_out_din <= fifo_out_din_c;
            fifo_out_wr_en <= fifo_out_wr_en_c;
        end
    end

    always @* begin
        fifo_out_din_c = RELU(fifo_in_dout);
        fifo_out_wr_en_c = 1'b0;
        fifo_in_rd_en = 1'b0;
        
        if (fifo_in_empty == 1'b0 && fifo_out_full == 1'b0) begin
            fifo_in_rd_en = 1'b1;
            fifo_out_wr_en_c = 1'b1;
        end
    end

endmodule
