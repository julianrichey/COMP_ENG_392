
`timescale 1 ns/1 ns


module sobel #(
    parameter integer DWIDTH_IN, //24 bits
    parameter integer DWIDTH_OUT //8 bits
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

    //shift reg

    //with this code, you can assume that, every cycle, you have the 3x3 grayscale input you want
    //given the pixels [1,2,3,721,722,723,1441,1442,1443], shift_reg is formatted like so:
    //

    reg [7:0] shift_reg [0:2] [0:2];

    integer i,j;
    always @(posedge clock) begin
        if (reset) begin
            for (i=0; i<3; i=i+1) begin
                for (j=0; j<3; j=j+1) begin
                    q[i][j] <= 8'h00;
                end
            end
        end else begin
            
        end
    end





    reg [FIFO_DWIDTH_OUT-1:0] data, data_c;
    reg is_data, is_data_c;

    always @(posedge clock) begin
        
    end

    always @* begin
        
    end

endmodule
