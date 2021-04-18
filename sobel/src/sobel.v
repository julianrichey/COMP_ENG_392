
`timescale 1 ns/1 ns


module sobel #(
    parameter integer DWIDTH_IN, //24 bits
    parameter integer DWIDTH_OUT //8 bits
) (
    input clock,
    input reset,

    //fifo in
    output reg fifo_in_rd_en,
    input [DWIDTH_IN-1:0] fifo_in_dout, //{1443, 723, 3}, i.e. larget index will grab largest pixel number
    input fifo_in_empty,

    //fifo out
    output reg fifo_out_wr_en,
    output reg [DWIDTH_OUT-1:0] fifo_out_din,
    input fifo_out_full
);
    //bmps are stored row major, starting at the lower left corner. use x,y for which column, which row. so 0,1 is 1 right of lower left corner
    //with this shfit_reg code, you can assume that, every cycle, you have the 3x3 grayscale input you want
        //the [7:0] refers to which bit
        //the 1st [0:2] refers to y
        //the 2nd [0:2] refers to x
        //so, shift_reg[1][2][6] refers to the 7th bit of the pixel at x,y coords 1,2 within the matrix if coords are 0 indexed
    //given the matrix of pixels 1,2,3,721,722,723,1441,1442,1443
        //on the bmp, these are the following, where x is the lower left hand corner
            // 000000
            // 011100
            // 011100
            // x11100
        //shift_reg accesses these as follows
            //shift_reg[1][0] is pixel 2
            //shift_reg[0][1] is pixel 721
            //shift_reg[2][2] is pixel 1444

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
            for (i=0; i<3; i=i+1) begin
                for (j=0; j<3; j=j+1) begin
                    shift_reg[i][j] <= (i<2) ? shift_reg[i+1][j] : fifo_in_dout[(8*(1+j))-1:8*j];
                end
            end
            /* //should do the following:
            shift_reg[0][0] <= shift_reg[1][0];
            shift_reg[1][0] <= shift_reg[2][0];
            shift_reg[2][0] <= fifo_in_dout[(8*(1+0))-1:8*0];
            shift_reg[0][1] <= shift_reg[1][1];
            shift_reg[1][1] <= shift_reg[2][1];
            shift_reg[2][1] <= fifo_in_dout[(8*(1+1))-1:8*1];
            shift_reg[0][2] <= shift_reg[1][2];
            shift_reg[1][2] <= shift_reg[2][2];
            shift_reg[2][2] <= fifo_in_dout[(8*(1+2))-1:8*2];
            */
        end
    end

    reg [DWIDTH_OUT-1:0] data, data_c;
    reg is_data, is_data_c;

    always @(posedge clock) begin
        if (reset) begin
            fifo_in_rd_en <= 1'b0;
            fifo_out_wr_en <= 1'b0;
            fifo_out_din <= 8'h00;
            is_data <= 1'b0;
        end else begin
            data <= data_c;
            is_data <= is_data_c;
        end
    end

    always @* begin
        //default values
        data_c = data;
        fifo_in_rd_en = 1'b0;
        fifo_out_wr_en = 1'b0;
        fifo_out_din = data;
        is_data_c = 1'b0;

        if (fifo_in_empty == 1'b0) begin
            is_data_c = 1'b1;
            fifo_in_rd_en = 1'b1;

            //use 9 values in shift_reg to compute data_c here
            // data_c = func(shift_reg)
        end

        if (fifo_out_full == 1'b0 && is_data == 1'b1) begin
            fifo_out_wr_en = 1'b1;
        end
    end

endmodule
