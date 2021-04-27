/*
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





oh interesting
if x and y refer to the square of the upper right corner of the window
0,0 is the lower left, the first real value taken from fifo_in_dout
the max values of x and y will be IMG_WIDTH+(WINDOW_SIZE/2)-1 and IMG_HEIGHT+(WINDOW_SIZE/2)-1
because, for the upper right corner output, the window will be centered on this upper right pixel of the real image
and the padding is (WINDOW_SIZE/2) past that in both directions



assumptions:
window is smaller than image
    if this changes later one, may need to carefully evaluate if/else logic in combinational block





problems
output timing
    should shift_reg_c or shift_reg be passed to sobel_op?
    probably shift_reg
    this requires delaying fifo_out_wr_en by one cycle
    fifo_out_wr_en must be delayed another cycle if sobel_op output is registered
left, right edges
    i was hoping that MIDDLOGUE could just continuously input+output, but i dont think this is the case
    for the 3x3 case, each time the window reaches a right edge there are two special cycles with a skip in the middle
        when x=IMG_WIDTH-1, normal (input and output)
        when x=IMG_WIDTH, can output, but no input bc pad
        x=IMG_WIDTH+1 is skipped. dont need to spend a cycle on it, x=IMG_WIDTH then x=0 the cycle after
        when x=0, can input, but no output bc pad
        when x=1, normal (input and output)


*/



`timescale 1 ns / 1 ns

module sobel #(
    parameter integer WINDOW_SIZE,
    parameter integer STRIDE,

    parameter integer DWIDTH_IN,
    parameter integer DWIDTH_OUT,

    parameter integer IMG_WIDTH = 720,
    parameter integer IMG_HEIGHT = 540
) (
    input wire clock,
    input wire reset,

    //in
    output reg fifo_in_rd_en, 
    input [DWIDTH_IN-1:0] fifo_in_dout, 
    input fifo_in_empty,

    //out
    output reg fifo_out_wr_en,
    output [DWIDTH_OUT-1:0] fifo_out_din,
    input fifo_out_full
);

    //DWIDTH_IN = 8
    //DWIDTH_OUT = 8


    reg [1:0] state,state_c;
    localparam PROLOGUE = 2'b00; //input, no output
    localparam MIDDLOGUE = 2'b01; //output on right edge, input on left edge, input and output otherwise
    localparam EPILOGUE = 2'b11; //no input, output




    //for 3x3: 720*2 + 3 = 1443
    //for 5x5: 720*4 + 5 = 2885
    localparam integer REG_SIZE = IMG_WIDTH*(WINDOW_SIZE-1) + WINDOW_SIZE; 
    reg [7:0] shift_reg,shift_reg_c [0:REG_SIZE-1]; //todo: change everything to use dwidth_in, dwidth_out
    reg [15:0] count,count_c; //number of elements in shift_reg. todo: use log2
    
    localparam integer PADDING = WINDOW_SIZE / 2;
    





    reg [7:0] window [0:WINDOW_SIZE*WINDOW_SIZE-1];
    integer ii,jj;
    always @* begin
        for (ii=0; ii<WINDOW_SIZE; ii=ii+1) begin
            for (jj=0; jj<WINDOW_SIZE; jj=jj+1) begin
                window[ii*WINDOW_SIZE + jj] = shift_reg_c[ii*IMG_WIDTH + jj]; //shift_reg_c means that sobel_op doesnt have to wait a cycle for shift_reg to update
            end
        end
    end
    sobel_op #(
        .WINDOW_SIZE(WINDOW_SIZE),
        .DWIDTH_IN(DWIDTH_IN),
        .DWIDTH_OUT(DWIDTH_OUT)
    ) sobel_0 (
        .clock(clock),
        .reset(reset),
        .in(window),
        .out(fifo_out_din)
    );




    reg [12:0] x,x_c;
    reg [12:0] y,y_c; //todo: include the log2 function here, use it to parameterize size of x, y
    always @(posedge clock, posedge reset) begin
        if (reset == 1'b1) begin
            state <= PROLOGUE;
            count <= 'b0;
            x <= 'b0;
            y <= 'b0;
            for (i=0; i<REG_SIZE; i=i+1) begin
                shift_reg[i] <= 'b0; 
            end
        end else if (clock == 1'b1) begin
            state <= state_c;
            count <= count_c;
            x <= x_c;
            y <= y_c;
            shift_reg <= shift_reg_c;
        end
    end

    integer i,j;
    always @* begin
        state_c = state;
        count_c = count;
        x_c = x;
        y_c = y;
        shift_reg_c = shift_reg;

        fifo_in_rd_en = 1'b0;
        fifo_out_wr_en = 1'b0;

        case (state)
            PROLOGUE: begin
                if (fifo_in_empty == 1'b0) begin
                    fifo_in_rd_en = 1'b1;

                    if (x == 0 && y == 0) begin //clear out shift_reg for new frame
                        for (i=1; i<REG_SIZE; i=i+1) begin
                            shift_reg_c[i] = 'b0;
                        end
                        shift_reg_c[0] = fifo_in_dout;
                        x_c = x + 'b1;
                        y_c = y;
                    end else if (x == IMG_WIDTH-1) begin
                        for (i=1+(PADDING*2); i<REG_SIZE; i=i+1) begin
                            shift_reg_c[i] = shift_reg[i-1-(PADDING*2)]; //can skip forward like this because this isnt outputting yet- can skip over PADDING*2 instead of just PADDING elements
                        end
                        shift_reg_c[PADDING*2] = fifo_in_dout;
                        for (i=0; i<PADDING*2; i=i+1) begin
                            shift_reg_c[i] = 'b0;
                        end
                        x_c = 'b0;
                        y_c = y + 'b1;
                    end else begin
                        for (i=1; i<REG_SIZE; i=i+1) begin
                            shift_reg_c[i] = shift_reg[i-1];
                        end
                        shift_reg_c[0] = fifo_in_dout;
                        x_c = x + 'b1;
                        y_c = y;
                    end

                    if (x == PADDING-1 && y == PADDING) begin //-1 so that x=PADDING,y=PADDING on middlogue start
                        state_c = MIDDLOGUE;
                    end
                end
            end

            MIDDLOGUE: begin
                if (x >= IMG_WIDTH && fifo_out_full == 1'b0) begin //left edge
                    fifo_out_wr_en = 1'b1;
                    
                end else if (x < PADDING && fifo_in_empty == 1'b0) begin //right edge
                    fifo_in_rd_en = 1'b1;
                    //if x = 0, shift shift_reg by PADDING for each of the windows with neither reads nor writes
                    //or maybe do that in the first condition above

                end else if (fifo_in_empty == 1'b0 && fifo_out_full == 1'b0) begin
                    fifo_in_rd_en = 1'b1;
                    fifo_out_wr_en = 1'b1;

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

            EPILOGUE: begin
                if (fifo_out_full == 1'b0) begin
                    fifo_out_wr_en = 1'b1;

                    if (x == IMG_WIDTH+1) begin
                        for (i=1+(PADDING*2); i<REG_SIZE; i=i+1) begin
                            shift_reg_c[i] = shift_reg[i-1-(PADDING*2)];
                        end
                        for (i=0; i<1+PADDING*2; i=i+1) begin
                            shift_reg_c[i] = 'b0;
                        end
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
               
                    if (x == IMG_WIDTH+PADDING-1 && y == IMG_HEIGHT+PADDING-1) begin
                        state_c = PROLOGUE; //todo: confirm that this module works when a new frame is given straight away
                    end
                end
            end
        endcase
    end
endmodule
