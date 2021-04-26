/*
1. figure out current errors
    problems with data and shift reg
2. verify sobel against c output
    add conditions for edges, make sure padding works
3. parameterize this to hell, then verify sobel again
    in, out widths
    3x3, 5x5, 7x7, 9x9, 11x11 and the padding that has to happen for each
    instantiate sobel_op only based on a parameter
4. write a 'gaussian_op'
    this file should be exact same, just instantiate a different module
5. verify gaussian against c output
6. parameterize stride
    might be easy or hard... not sure yet. dont worry about until later
7. make sure this works in a loop of prologue->image->epilogue to process multiple frames



*/



`timescale 1 ns / 1 ns

module sobel #(
    parameter integer DWIDTH_IN,
    parameter integer DWIDTH_OUT,

    parameter integer IMG_WIDTH = 720,
    parameter integer IMG_HEIGHT = 540
)(
    input wire clock,
    input wire reset,

    //in
    output reg in_rd_en, 
    input [DWIDTH_IN-1:0] in_dout, 
    input in_empty,

    //out
    output reg out_wr_en, 
    output reg [DWIDTH_OUT-1:0] out_din, 
    input out_full
);

//DWIDTH_IN = 8
//DWIDTH_OUT = 8
    localparam integer REG_SIZE = IMG_WIDTH*2 + 3; //REG_SIZE should be 1443(720*2 + 3)
    reg [7:0] shift_reg [0:REG_SIZE - 1];
    reg [7:0] shift_reg_c [0:REG_SIZE - 1];
    
    reg [12:0] x,x_c,y,y_c; //todo: include the log2 function here, use it to parameterize size of x, y
    
    reg [7:0] data [0:8];
    
    reg [15:0] count,count_c;

    integer i,j;

    reg [1:0] state,state_c;
    localparam s0 = 2'b00;
    localparam s1 = 2'b01;
    localparam s2 = 2'b10;

    wire [7:0] grad;
    sobel_op #(
        .DWIDTH_IN(8*9),
        .DWIDTH_OUT(8)
    ) sobel_0 (
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
            for (i=0;i<REG_SIZE;i=i+1) begin
                shift_reg[i] <= 'b0; 
            end
            state <= s0;

        end else if (clock == 1'b1) begin
            count <= count_c;
            x <= x_c;
            y <= y_c;
            shift_reg <= shift_reg_c;
            state <= state_c;
        end
    end

    always @* begin
        state_c = state;
        x_c = x;
        y_c = y;
        shift_reg_c = shift_reg;
        in_rd_en = 1'b0;
        out_wr_en = 1'b0;
        out_din = grad;
        count_c = count;

        for (i=0; i<3; i=i+1) begin
            for (j=0; j<3; j=j+1) begin
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
                        state_c = s1;
                    end
                end
            end

            s1: begin
                if (in_empty == 1'b0) begin
                    in_rd_en = 1'b1;
                    for(i=REG_SIZE-1; i>0; i=i-1) begin
                        shift_reg_c[i] = shift_reg[i-1]; 
                    end
                    shift_reg_c[0] = in_dout;
                    x_c = x + 12'b1;
                    if ((y == IMG_HEIGHT - 1) && (x == IMG_WIDTH - 1)) begin
                        y_c = 'b0;
                        x_c = 'b0;
                    end else if (x == IMG_WIDTH - 1) begin
                        x_c = 'b0;
                        y_c = y +12'b1;
                    end
                    state_c = s2;
                end
            end

            s2: begin
                if (out_full == 1'b0) begin
                    //checks for edges here to set out_wr_en
                    out_wr_en = 1'b1;
                    state_c = s1;
                end
            end
            
            default: begin
                x_c = 'b0;
                y_c = 'b0;
                //shift_reg_c = 0//put something here
                state_c = s0;
            end
        endcase
    end
endmodule
