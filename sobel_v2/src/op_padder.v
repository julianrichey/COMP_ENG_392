/*

The main goal of this module is to read from and write to fifos every cycle. 
This doesn't matter too much, but was a good time. 


// 1. figure out current errors
//     problems with window and shift reg
// 2. verify sobel against c output
//     add conditions for edges, make sure padding works
// 3. parameterize this to hell, then verify sobel again
//     in, out widths
//     3x3, 5x5, 7x7, 9x9, 11x11 and the padding that has to happen for each
//     instantiate sobel_op only based on a parameter
// 4. write a 'gaussian_op'
//     this file should be exact same, just instantiate a different module
5. verify gaussian against c output 
    TODO - sometimes, gaussian rounds incorrectly.
    when a bad round happens, it happens up when the number is small and down when the number is large
    what?!?
6. parameterize stride?!
    might be easy or hard... not sure yet. dont worry about until later
7. make sure this works in a loop of prologue->image->epilogue to process multiple frames


*/



`timescale 1 ns / 1 ns

`define CLOG2(x) \
    (x <= 2) ? 1 : \
    (x <= 4) ? 2 : \
    (x <= 8) ? 3 : \
    (x <= 16) ? 4 : \
    (x <= 32) ? 5 : \
    (x <= 64) ? 6 : \
    (x <= 128) ? 7 : \
    (x <= 256) ? 8 : \
    (x <= 512) ? 9 : \
    (x <= 1024) ? 10 : \
    (x <= 2048) ? 11 : \
    (x <= 4096) ? 12 : \
    -1

module op_padder #(
    parameter integer OP,

    parameter integer WINDOW_SIZE,
    parameter integer STRIDE,

    parameter integer DWIDTH_IN,
    parameter integer DWIDTH_OUT,

    parameter integer IMG_WIDTH,
    parameter integer IMG_HEIGHT
) (
    input wire clock,
    input wire reset,

    output reg fifo_in_rd_en, 
    input [DWIDTH_IN-1:0] fifo_in_dout, 
    input fifo_in_empty,

    output reg fifo_out_wr_en,
    output reg [DWIDTH_OUT-1:0] fifo_out_din,
    input fifo_out_full
);
    wire [DWIDTH_OUT-1:0] fifo_out_din_c;
    reg fifo_out_wr_en_shift_reg_c;
    reg [1:0] fifo_out_wr_en_shift_reg;

    localparam integer GAUSSIAN_OP = 0;
    localparam integer SOBEL_OP = 1;


    reg [1:0] state,state_c;
    localparam PROLOGUE = 2'b00; //input, no output
    localparam MIDDLOGUE = 2'b01; //input and output
    localparam EPILOGUE = 2'b10; //no input, output
    localparam TEMP_END_STATE = 2'b11; //nothing

    localparam integer PADDING = WINDOW_SIZE / 2;
    localparam integer REG_SIZE = IMG_WIDTH*(WINDOW_SIZE-1) + WINDOW_SIZE + PADDING*(WINDOW_SIZE-1)*2; 
    reg [DWIDTH_IN-1:0] shift_reg [0:REG_SIZE-1];
    reg [DWIDTH_IN-1:0] shift_reg_c [0:REG_SIZE-1];
    
    //for continuous reading and writing. otherwise, could only do one at a time on edges.
    reg [DWIDTH_IN-1:0] edge_storage [0:PADDING-1];
    reg [DWIDTH_IN-1:0] edge_storage_c [0:PADDING-1];

    reg [`CLOG2(IMG_WIDTH + WINDOW_SIZE)-1:0] x,x_c;
    reg [`CLOG2(IMG_HEIGHT + WINDOW_SIZE)-1:0] y,y_c;
    reg [`CLOG2(IMG_WIDTH + WINDOW_SIZE)-1:0] x_last;
    reg [`CLOG2(IMG_HEIGHT + WINDOW_SIZE)-1:0] y_last;
    
    reg [(DWIDTH_IN*WINDOW_SIZE*WINDOW_SIZE)-1:0] window;
    integer ii,jj;
    always @* begin
        for (ii=0; ii<WINDOW_SIZE; ii=ii+1) begin
            for (jj=0; jj<WINDOW_SIZE; jj=jj+1) begin
                window[(ii*WINDOW_SIZE + jj)*DWIDTH_IN +: DWIDTH_IN] = shift_reg[ii*(IMG_WIDTH+PADDING*2) + jj];
            end
        end
    end


    if (OP == SOBEL_OP) begin
        op_sobel #(
            .DWIDTH_IN(DWIDTH_IN*WINDOW_SIZE*WINDOW_SIZE),
            .DWIDTH_OUT(DWIDTH_OUT),
            .IMG_WIDTH(IMG_WIDTH),
            .IMG_HEIGHT(IMG_HEIGHT)
        ) op_sobel_0 (
            .clock(clock),
            .reset(reset),
            .x(x),
            .y(y),
            .in(window),
            .out(fifo_out_din_c)
        );
    end else if (OP == GAUSSIAN_OP) begin
        op_gaussian #(
            .DWIDTH_IN(DWIDTH_IN*WINDOW_SIZE*WINDOW_SIZE),
            .DWIDTH_OUT(DWIDTH_OUT),
            .IMG_WIDTH(IMG_WIDTH),
            .IMG_HEIGHT(IMG_HEIGHT)
        ) op_gaussian_0 (
            .clock(clock),
            .reset(reset),
            .x(x_last),
            .y(y_last),
            .in(window),
            .out(fifo_out_din_c)
        );
    end else begin
        //future OPs
    end

    integer iii;
    always @(posedge clock) begin
        if (reset == 1'b1) begin
            state <= PROLOGUE;
            x <= 'b0;
            y <= 'b0;
            x_last <= 'b0;
            y_last <= 'b0;
            for (iii=0; iii<REG_SIZE; iii=iii+1) begin
                shift_reg[iii] <= 'b0;
            end
            for (iii=0; iii<PADDING; iii=iii+1) begin
                edge_storage[iii] <= 'b0;
            end
            fifo_out_din <= 'b0;
            fifo_out_wr_en_shift_reg[0] <= 1'b0;
            fifo_out_wr_en_shift_reg[1] <= 1'b0;
            fifo_out_wr_en <= 1'b0;

        end else begin
            state <= state_c;
            x <= x_c;
            y <= y_c;
            x_last <= x;
            y_last <= y;
            for (iii=0; iii<REG_SIZE; iii=iii+1) begin
                shift_reg[iii] <= shift_reg_c[iii];
            end
            for (iii=0; iii<PADDING; iii=iii+1) begin
                edge_storage[iii] <= edge_storage_c[iii];
            end
            fifo_out_din <= fifo_out_din_c;
            fifo_out_wr_en_shift_reg[0] <= fifo_out_wr_en_shift_reg_c;
            fifo_out_wr_en_shift_reg[1] <= fifo_out_wr_en_shift_reg[0];
            fifo_out_wr_en <= fifo_out_wr_en_shift_reg[1];
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
        fifo_out_wr_en_shift_reg_c = 1'b0;

        //states:
        //  prologue - read every cycle, no write
        //  middlogue - read and write every cycle. on right edges, store to edge_storage temporarily
        //  epilogue - write every cycle, no read

        //structure of conditions:
        //  x=padding - the start of each row
        //  x>=img_width - PADDING cycles of writing to edge_storage
        //      within these, there is a check
        //      one case is for when still writing to edge_storage
        //      other case is going to next row
        //  else - normally increment

        //special cases:
        //  in prologue, start at x=0 instead of x=padding
        //      here, clear shift_reg, which serves as the bottom edge padding
        //  each has their own conditions to transition to the next state
        case (state)
            PROLOGUE: begin
                if (fifo_in_empty == 1'b0) begin
                    fifo_in_rd_en = 1'b1;

                    if (x == 0 && y == 0) begin
                        for (i=1; i<REG_SIZE; i=i+1) begin
                            shift_reg_c[i] = 'b0; //clear out shift_reg for new frame
                        end
                        shift_reg_c[0] = fifo_in_dout;
                        x_c = x + 'b1;
                        y_c = y;

                    end else if (x == PADDING && y > 0) begin //first time x=padding, edge_storage not filled, bc start from x=0,y=0
                        for (i=WINDOW_SIZE; i<REG_SIZE; i=i+1) begin
                            shift_reg_c[i] = shift_reg[i-WINDOW_SIZE];
                        end
                        for (i=PADDING+1; i<WINDOW_SIZE; i=i+i) begin
                            shift_reg_c[i] = 'b0;
                        end
                        for (i=1; i<PADDING+1; i=i+i) begin
                            shift_reg_c[i] = edge_storage[i-1];
                        end
                        shift_reg_c[0] = fifo_in_dout;

                        x_c = x + 'b1;
                        y_c = y;

                    end else if (x >= IMG_WIDTH) begin
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
                            if (y == PADDING-1) begin
                                state_c = MIDDLOGUE;
                            end
                        end
                        
                    end else begin
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
                    fifo_out_wr_en_shift_reg_c = 1'b1;


                    if (x == PADDING) begin //shift, pad, consume edge_storage, fill current
                        for (i=WINDOW_SIZE; i<REG_SIZE; i=i+1) begin
                            shift_reg_c[i] = shift_reg[i-WINDOW_SIZE];
                        end
                        for (i=PADDING+1; i<WINDOW_SIZE; i=i+i) begin
                            shift_reg_c[i] = 'b0;
                        end
                        for (i=1; i<PADDING+1; i=i+i) begin
                            shift_reg_c[i] = edge_storage[i-1];
                        end
                        shift_reg_c[0] = fifo_in_dout;

                        x_c = x + 'b1;
                        y_c = y;

                    end else if (x >= IMG_WIDTH) begin //store one read per cycle, even if still on right edge
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
                    fifo_out_wr_en_shift_reg_c = 1'b1;

                    if (x == PADDING) begin
                        for (i=WINDOW_SIZE; i<REG_SIZE; i=i+1) begin
                            shift_reg_c[i] = shift_reg[i-WINDOW_SIZE];
                        end

                        for (i=1; i<WINDOW_SIZE; i=i+i) begin
                            shift_reg_c[i] = 'b0;
                        end
                        shift_reg_c[0] = 'b0;

                        x_c = x + 'b1;
                        y_c = y;

                    end else if (x == IMG_WIDTH+PADDING-1) begin
                        for (i=1; i<REG_SIZE; i=i+1) begin
                            shift_reg_c[i] = shift_reg[i-1];
                        end
                        shift_reg_c[0] = 'b0;

                        if (y == IMG_HEIGHT+PADDING-1) begin
                            state_c = TEMP_END_STATE;
                            x_c = 'b0;
                            y_c = 'b0;
                        end else begin
                            x_c = PADDING;
                            y_c = y + 'b1;
                        end

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
                //do nothing
                //todo: just go back to prologue from epilogue for new frame
            end
        endcase
    end
endmodule
