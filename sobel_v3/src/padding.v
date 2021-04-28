`timescale 1 ns / 1 ns

module padding #(
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

    //coordinates in our image 

    reg [15:0] count,count_c;


    reg [12:0] x,x_c,y,y_c;

    reg[1:0] state,next_state;

    localparam s0 = 2'b00;
    localparam s1 = 2'b01;
    localparam s2 = 2'b10;
    localparam s3 = 2'b11;

    always @(posedge clock, posedge reset) begin
        if (reset == 1'b1) begin
            count <= 'b0;
            x <= 'b0;
            y <= 'b0;
            state <= s0;

        end else if (clock == 1'b1) begin
            x <= x_c;
            y <= y_c;
            count <= count_c;
            state <= next_state;
        end
    end


//how do we know what to do when we get to a new image???
    //always @(state,in_empty,in_dout,out_full,x,y,shift_reg,count) begin
    always @(*) begin
        next_state = state;
        //what do I put for in_rd_en for each of these states?
        in_rd_en = 1'b0;
        out_wr_en = 1'b0;
        out_din = in_dout;
        //count_c <= count;
        x_c = x;
        y_c = y;


        case(state) 
        //prologue, write 0s to output fifo until img_width + 1 cycles have gone by (MIGHT NEED TO BE IF x==IMG_WIDTH)
        s0: begin
            //first row
            if(y == 'b0 && out_full == 1'b0) begin
                //output 0 to the out_din
                x_c = x+1;
                out_din = 0;
                out_wr_en = 1'b1;
                if (x == IMG_WIDTH + 1) begin
                    x_c = 0;
                    y_c = y+1;
                    //now we are ready to output a line of our data
                    next_state = s1;
                end
            end
            
        

        end
        s1: begin
            if(x == 0 && out_full == 0) begin
                x_c = x+1;
                out_din = 0;
                out_wr_en = 1'b1;
            end
            else if(x == IMG_WIDTH + 1 && out_full == 0) begin
                x_c = 0;
                y_c = y+1;
                out_din = 0;
                out_wr_en = 1'b1;
                if(y == IMG_HEIGHT) begin
                    next_state = s2;
                end
            end
            else if(out_full == 0 && in_empty == 0) begin
                //read from fifo 
                //only case where we read from input fifo
                in_rd_en = 1'b1;
                out_din = in_dout;
                //set rd_en and wr_en
            end
        end
        //epilogue happens when we finish one frame(we know y==height + 1)
        s2: begin
            if(out_full == 0) begin
                //output 0 to the out_din
                x_c = x+1;
                out_din = 0;
                out_wr_en = 1'b1;
                if (x == IMG_WIDTH + 1) begin
                    x_c = 0;
                    y_c = 0;
                    //prepare for the next frame
                    state = s0;
                end
            end

        end
/*
        s0: begin  //first state that inserts 0 into first row
            if(in_empty == 1'b0) begin
                //don't want to read until we have outputted the first row of zeros
                out_wr_en <= 1'b1;
                count_c <= count + 16'b1;
                if(count >= IMG_WIDTH) begin //total number of times we output a 0 to output fifo is IMG_WIDTH + 1
                    //reset count to 0 and move on
                    count_c <= 'b0;
                    next_state <= s1;
                end
            end


        end
        //state that adds 2 0 values to the fifo out, which is just padding
        s1: begin
            if(in_empty == 1'b0) begin
                //in_rd_en <= 1'b1;
                count_c <= count + 16'b1;
                out_wr_en <= 1'b1;
                if(count >= 1) begin //add 2 more 0 to the output fifo, then begin passing actual data through the fifo
                    //reset count to 0 and move on
                    count_c <= 'b0;
                    next_state <= s2;
                end
                //next_state <= s1;

            end
        end
        s2: begin
            if(out_full == 1'b0) begin
                out_wr_en <= 1'b1;
                out_din <= in_dout;
                if(count >= IMG_WIDTH - 1) begin //total number of times we output a 0 to output fifo is IMG_WIDTH + 1
                    //reset count to 0 and move on
                    count_c <= 'b0;
                    next_state <= s1;
                end
                //next_state <= s1;
                
            end
        end
        */
        default: begin
            next_state <= s0;
        end

    endcase
    
   end

endmodule