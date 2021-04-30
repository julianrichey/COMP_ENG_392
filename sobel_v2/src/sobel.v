/*

The main goal of this module is to read from and write to fifos every cycle. 
This doesn't matter too much, but was a good time. 






// 1. figure out current errors
//     problems with window and shift reg
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


assumptions:
window is smaller than image
    if this changes later one, may need to carefully evaluate if/else logic in combinational block

*/



`timescale 1 ns / 1 ns

module sobel #(
    parameter integer WINDOW_SIZE,
    parameter integer STRIDE,

    parameter integer DWIDTH_IN,
    parameter integer DWIDTH_OUT,

    parameter integer IMG_WIDTH,
    parameter integer IMG_HEIGHT
) (
    input wire clock,
    input wire reset,

    //in
    output reg fifo_in_rd_en, 
    input [DWIDTH_IN-1:0] fifo_in_dout, 
    input fifo_in_empty,

    //out
    output reg fifo_out_wr_en,
    output reg [DWIDTH_OUT-1:0] fifo_out_din,
    input fifo_out_full
);
    wire [DWIDTH_OUT-1:0] fifo_out_din_c;
    reg fifo_out_wr_en_next_c; //probably need a tiny shift reg for this? i will see how many cycles back this needs to be pushed
    reg fifo_out_wr_en_next;
    reg [3:0] fifo_out_wr_en_shift_reg;

    //assume these for now
    //DWIDTH_IN = 8
    //DWIDTH_OUT = 8


    reg [1:0] state,state_c;
    localparam PROLOGUE = 2'b00; //input, no output
    localparam MIDDLOGUE = 2'b01; //output on right edge, input on left edge, input and output otherwise
    localparam EPILOGUE = 2'b10; //no input, output
    localparam TEMP_END_STATE = 2'b11;



    //for 3x3: 720*2 + 3 = 1443 WAIT THIS NEEDS TO INCLUDE PADDING
    //for 5x5: 720*4 + 5 = 2885
    localparam integer PADDING = WINDOW_SIZE / 2;
    localparam integer REG_SIZE = IMG_WIDTH*(WINDOW_SIZE-1) + WINDOW_SIZE + PADDING*(WINDOW_SIZE-1)*2; 
    reg [7:0] shift_reg [0:REG_SIZE-1]; //todo: change everything to use dwidth_in, dwidth_out
    reg [7:0] shift_reg_c [0:REG_SIZE-1];
    
    //for continuous reading and writing
    reg [7:0] edge_storage [0:PADDING-1];
    reg [7:0] edge_storage_c [0:PADDING-1];
    


    
    reg [(DWIDTH_IN*WINDOW_SIZE*WINDOW_SIZE)-1:0] window;
    integer ii,jj;
    always @* begin
        for (ii=0; ii<WINDOW_SIZE; ii=ii+1) begin
            for (jj=0; jj<WINDOW_SIZE; jj=jj+1) begin
                window[(ii*WINDOW_SIZE + jj)*8 +: 8] = shift_reg[ii*(IMG_WIDTH+PADDING*2) + jj];
            end
        end
    end
    sobel_op #(
        .DWIDTH_IN(DWIDTH_IN*WINDOW_SIZE*WINDOW_SIZE),
        .DWIDTH_OUT(DWIDTH_OUT)
    ) sobel_op_0 (
        .clock(clock),
        .reset(reset),
        .in(window),
        .out(fifo_out_din_c)
    );


    reg [12:0] x,x_c;
    reg [12:0] y,y_c; //todo: include the log2 function here, use it to parameterize size of x, y
    integer iii;
    always @(posedge clock) begin
        if (reset == 1'b1) begin
            state <= PROLOGUE;
            x <= 'b0;
            y <= 'b0;
            for (iii=0; iii<REG_SIZE; iii=iii+1) begin
                shift_reg[iii] <= 'b0;
            end
            for (iii=0; iii<PADDING; iii=iii+1) begin
                edge_storage[iii] <= 'b0;
            end

            fifo_out_din <= 'b0;
            fifo_out_wr_en_next <= 1'b0;
            fifo_out_wr_en_shift_reg[0] <= 1'b0;
            fifo_out_wr_en <= 1'b0;
        end else begin
            state <= state_c;
            x <= x_c;
            y <= y_c;
            for (iii=0; iii<REG_SIZE; iii=iii+1) begin
                shift_reg[iii] <= shift_reg_c[iii];
            end
            for (iii=0; iii<PADDING; iii=iii+1) begin
                edge_storage[iii] <= edge_storage_c[iii];
            end

            fifo_out_din <= fifo_out_din_c;
            fifo_out_wr_en_next <= fifo_out_wr_en_next_c;
            fifo_out_wr_en_shift_reg[0] <= fifo_out_wr_en_next;
            // fifo_out_wr_en_shift_reg[1] <= fifo_out_wr_en_shift_reg[0];
            // fifo_out_wr_en_shift_reg[2] <= fifo_out_wr_en_shift_reg[1];
            fifo_out_wr_en <= fifo_out_wr_en_shift_reg[0];
        end
    end

    integer i;
    always @* begin
        state_c = state;
        x_c = x;
        y_c = y;
        for (i=0; i<REG_SIZE; i=i+1) begin
            shift_reg_c[i] = shift_reg[i];
        end
        for (i=0; i<PADDING; i=i+1) begin
            edge_storage_c[i] = edge_storage[i];
        end

        fifo_in_rd_en = 1'b0;
        fifo_out_wr_en_next_c = 1'b0;

        case (state)
            PROLOGUE: begin
                if (fifo_in_empty == 1'b0) begin
                    fifo_in_rd_en = 1'b1;

                    if (x == 0 && y == 0) begin //clear out shift_reg for new frame
                        for (i=1; i<REG_SIZE; i=i+1) begin
                            shift_reg_c[i] = 'b0;
                        end
                        shift_reg_c[0] = fifo_in_dout; //some of the cleared out portion 'is' the padding on the bottom edge
                        x_c = x + 'b1;
                        y_c = y;

                    end else if (x >= IMG_WIDTH) begin //changed to be like middlogue
                        for (i=1; i<REG_SIZE; i=i+1) begin
                            shift_reg_c[i] = shift_reg[i-1];
                        end
                        shift_reg_c[0] = 'b0;
                        edge_storage_c[IMG_WIDTH+PADDING-x-1] = fifo_in_dout;
                        if (x < IMG_WIDTH+PADDING-1) begin
                            x_c = x + 'b1;
                            y_c = y;
                        end else begin
                            x_c = PADDING;
                            y_c = y + 'b1;
                            if (y == PADDING - 1) begin
                                state_c = MIDDLOGUE;
                            end
                        end
                        
                    end else begin //todo: will need to handle receiving from edge storage for any greater than 3x3
                        for (i=1; i<REG_SIZE; i=i+1) begin
                            shift_reg_c[i] = shift_reg[i-1];
                        end
                        shift_reg_c[0] = fifo_in_dout;
                        x_c = x + 'b1;
                        y_c = y;
                    end
                end
            end

            MIDDLOGUE: begin
                if (fifo_in_empty == 1'b0 && fifo_out_full == 1'b0) begin
                    fifo_in_rd_en = 1'b1;
                    fifo_out_wr_en_next_c = 1'b1;

                    if (x >= IMG_WIDTH) begin //store one read per cycle, even if still on right edge
                        for (i=1; i<REG_SIZE; i=i+1) begin
                            shift_reg_c[i] = shift_reg[i-1];
                        end
                        shift_reg_c[0] = 'b0;
                        edge_storage_c[IMG_WIDTH+PADDING-x-1] = fifo_in_dout; //this expression lets it be accessed easily
                        if (x < IMG_WIDTH+PADDING-1) begin
                            x_c = x + 'b1;
                            y_c = y;
                        end else begin
                            x_c = PADDING;
                            y_c = y + 'b1;
                        end

                    end else if (x == PADDING) begin //consume all stored reads in one go
                    //this parameterization will need to work. why doesnt it yet? probably just off by 1 somewhere
                        // for (i=WINDOW_SIZE; i<REG_SIZE; i=i+1) begin
                        //     shift_reg_c[i] = shift_reg[i-WINDOW_SIZE];
                        // end
                        // for (i=0; i<PADDING; i=i+i) begin
                        //     shift_reg_c[i+PADDING+1] = 'b0;
                        // end
                        // for (i=0; i<PADDING; i=i+i) begin
                        //     shift_reg_c[i+1] = edge_storage[i];
                        // end
                        // shift_reg_c[0] = fifo_in_dout;

                        for (i=3; i<REG_SIZE; i=i+1) begin
                            shift_reg_c[i] = shift_reg[i-3];
                        end
                        shift_reg_c[2] = 'b0;
                        shift_reg_c[1] = edge_storage[0];
                        shift_reg_c[0] = fifo_in_dout;

                        x_c = x + 'b1;
                        y_c = y;

                    end else begin
                        for (i=1; i<REG_SIZE; i=i+1) begin
                            shift_reg_c[i] = shift_reg[i-1];
                        end
                        shift_reg_c[0] = fifo_in_dout;

                        x_c = x + 'b1;
                        y_c = y;

                        if (x == IMG_WIDTH-1 && y == IMG_HEIGHT-1) begin
                            state_c = EPILOGUE;
                        end
                    end
                end
            end

            EPILOGUE: begin
                if (fifo_out_full == 1'b0) begin
                    fifo_out_wr_en_next_c = 1'b1;

                    if (x == IMG_WIDTH+PADDING-1 && y == IMG_HEIGHT+PADDING-1) begin
                        state_c = TEMP_END_STATE;
                        x_c = 'b0;
                        y_c = 'b0;
                    end else if (x == PADDING) begin
                        for (i=WINDOW_SIZE; i<REG_SIZE; i=i+1) begin
                            shift_reg_c[i] = shift_reg[i-WINDOW_SIZE];
                        end
                        for (i=0; i<WINDOW_SIZE; i=i+1) begin
                            shift_reg_c[i] = 'b0;
                        end
                        x_c = x + 'b1;
                        y_c = y;

                    end else if (x == IMG_WIDTH+PADDING-1) begin //todo: x>=, condition on x_c,y_c
                        for (i=1; i<REG_SIZE; i=i+1) begin
                            shift_reg_c[i] = shift_reg[i-1];
                        end
                        shift_reg_c[0] = 'b0;
                        x_c = PADDING;
                        y_c = y + 'b1;

                    end else begin
                        for (i=1; i<REG_SIZE; i=i+1) begin
                            shift_reg_c[i] = shift_reg[i-1];
                        end
                        shift_reg_c[i] = 'b0;
                        x_c = x + 'b1;
                        y_c = y;
                    end
                end
            end

            TEMP_END_STATE: begin
                // for (i=1; i<REG_SIZE; i=i+1) begin
                //     shift_reg_c[i] = shift_reg[i-1];
                // end
                // shift_reg_c[i] = 'b0;
            end
        endcase

        // for (ii=0; ii<WINDOW_SIZE; ii=ii+1) begin
        //     for (jj=0; jj<WINDOW_SIZE; jj=jj+1) begin
        //         window[ii*WINDOW_SIZE + jj] = shift_reg[ii*IMG_WIDTH + jj]; //shift_reg_c vs shift_reg??
        //     end
        // end
    end
endmodule
