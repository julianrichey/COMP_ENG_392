`timescale 1 ns / 1 ns

module sobel #(
    parameter integer IMG_WIDTH = 720, //8 bits
    parameter integer IMG_HEIGHT = 540 //8*9 bits
)(
    input wire clock,
    input wire reset,

    //fifo in
    output reg in_rd_en,
    input wire [7:0] in_dout, //{1443, 723, 3}, i.e. larget index will grab largest pixel number
    input wire in_empty,

    //fifo out
    output reg out_wr_en,
    output reg [7:0] out_din,
    input wire out_full
);

//DWIDTH_IN = 8
    localparam integer REG_SIZE = IMG_WIDTH*2 + 3; //REG_SIZE should be 1443(720*2 + 3)

    reg [7:0] shift_reg [0:REG_SIZE - 1];
    reg [7:0] shift_reg_c [0:REG_SIZE - 1];
    wire [7:0] grad;
    //coordinates in our image
    reg [12:0] x,x_c,y,y_c; //Not sure how big these need to be or even if they are the same size

    reg [7:0] data [0:8];
    reg [15:0] count,count_c;

    integer i,j;

    reg [1:0] state,next_state;

    localparam s0 = 2'b00;
    localparam s1 = 2'b01;
    localparam s2 = 2'b10;
    localparam s3 = 2'b11;

    sobel_op sobel_1( 
        .clock(clock),
        .reset(reset),
        .in(data),
        .out(grad)
    );

    always @(posedge clock, posedge reset) begin
        if (reset == 1'b1) begin
            x <= 'b0;
            y <= 'b0;
            count <= 'b0;
            for(i=0;i<REG_SIZE;i=i+1) begin
                shift_reg[i] <= 'b0; 
            end
            state <= s0;

        end else if (clock == 1'b1) begin
            count <= count_c;
            x <= x_c;
            y <= y_c;
            shift_reg <= shift_reg_c;
            state <= next_state;
        end
    end

    always @* begin
        next_state = state;
        x_c = x;
        y_c = y;
        shift_reg_c = shift_reg;
        in_rd_en = 1'b0;
        out_wr_en = 1'b0;
        out_din = grad;
        count_c = count;

        for (i=0;i<3;i=i+1) begin
            for(j=0;j<3;j=j+1) begin
                data[i*3 + j] = shift_reg[i*IMG_WIDTH + j];
            end
        end

        case (state)
            s0: begin
                x_c = 'b0;
                y_c = 'b0;
                if (in_empty == 1'b0) begin
                    in_rd_en = 1'b1;
                    for (i=REG_SIZE-1; i>0; i=i-1) begin
                        shift_reg_c[i] = shift_reg[i-1]; 
                    end
                    shift_reg_c[0] = in_dout;
                    count_c = count + 16'b1;
                    if(count == REG_SIZE - 1) begin
                        next_state = s1;
                    end
                end

            end
            s1: begin
                if(in_empty == 1'b0) begin
                    in_rd_en = 1'b1;
                    for(i=REG_SIZE-1;i>0;i=i-1) begin
                        shift_reg_c[i] = shift_reg[i-1]; 
                    end
                    shift_reg_c[0] = in_dout;
                    x_c = x + 12'b1;
                    if(y == IMG_HEIGHT - 1 && x == IMG_WIDTH - 1) begin
                        y_c = 'b0;
                        x_c = 'b0;
                    end else if(x == IMG_WIDTH - 1) begin
                        x_c = 'b0;
                        y_c = y +12'b1;
                    end
                    next_state = s2;
                end
            end
            s2: begin
                if(out_full == 1'b0) begin
                    //out_din = grad;
                    out_wr_en = 1'b1;
                    next_state = s1;
                end
            end
            default: begin
                x_c = 'b0;
                y_c = 'b0;
                //shift_reg_c = 0//put something here
                next_state = s0;
            end
        endcase
    end
endmodule
