`timescale 1 ns / 1 ns

module sobel (
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
    

    reg [7:0] shift_reg [0:2] [0:2];
    reg [7:0] grad,v;
    integer i,j;

    reg[1:0] state,next_state;

    localparam s0 = 2'b00;
    localparam s1 = 2'b01;
    localparam s2 = 2'b10;
    localparam s3 = 2'b11;

    always @(posedge clock, posedge reset) begin
        if (reset == 1'b1) begin
            out <= 'h0;
        end else if (clock == 1'b1) begin
            out <= out_c;
        end
    end

    always @(state,in_empty,in_dout,out_full,x,y,shift_reg) begin
        next_state <= state;
        x_c <= x;
        y_c <= y;
        shift_reg_c <= shift_reg;
        in_rd_en <= 1'b0;
        out_wr_en <= 1'b0;
        out_din <= 'b0;

        for(i=0;i<3;i=i+1) begin
            for(j=0;j<3;j=j+1) begin
                data[i*3 + j] = shift_reg[i*IMG_WIDTH + j];
            end
        end

        grad = 'b0;
        if( (x /= 0) and (x /= IMG_WIDTH-1) and (y /= 0) and (y /= IMG_HEIGHT-1)) begin
            grad = sobel_op(data);
        end

        case(state) 
        s0: begin
            x_c <= 0;
            y_c <= 0;
            shift_reg_c <= //initialize all of the shift register to zero
            next_state <= s1;
        end
        s1: begin
            if(in_empty == 1'b0) begin
                in_rd_en <= 1'b1;
                shift_reg_c[0:REG_SIZE-2] <= shift_reg[1 to REG_SIZE-1]; //REG_SIZE should be 1443(720*2 + 3)
                shift_reg_c[REG_SIZE-1] <= in_dout;
                x_c <= x + 1;
                if(x == WIDTH - 1) begin
                    x_c <= 'b0;
                    y_c <= y + 1;
                end
                if ( (y*WIDTH + x) == (WIDTH + 1)) begin
                    x_c <= x - 1;
                    y_c <= y - 1;
                    next_state <= s2;
                end
            end
        end
        s2: begin
            if(in_empty == 1'b0 and out_full == 1'b0) begin
                shift_reg_c[0:REG_SIZE-2] <= shift_reg[1 to REG_SIZE-1];
                shift_reg_c[REG_SIZE-1] <= in_dout;
                x_c <= x + 1;
                if(x == WIDTH - 1) begin
                    x_c <= 'b0;
                    y_c <= y + 1;
                end
                out_din <= grad;
                in_rd_en <= 1'b1;
                out_wr_en <= 1'b1;
                if(y = HEIGHT - 2 and x == WIDTH - 3) begin
                    next_state <= s3;
                end else begin
                    next_state <= s2;
                end
            end
        end
        s3: begin
            if(out_full == 1'b0) begin
                x_c <= x + 1;
                if(x == WIDTH - 1) begin
                    x_c <= 'b0;
                    y_c <= y + 1;
                end
                out_din <= grad;
                out_wr_en <= 1'b1;
                if( (X == WIDTH - 1) and (y == HEIGHT - 1)) begin
                    next_state <= s0;
                end
            end
        end
        default: begin
            x_c <= 'b0;
            y_c <= 'b0;
            shift_reg_c <= 0//put something here
            next_state <= s0;
        end

    end



endmodule
