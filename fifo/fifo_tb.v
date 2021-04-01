`timescale 1ns/1ns




// module producer;

// endmodule


// module consumer;

// endmodule


//to begin, no cdc
module fifo_tb;
    parameter depth = 8;
    parameter width = 8;

    reg rst;
    reg clk;
    reg wr_en;
    reg [width-1:0] din;
    wire full;
    reg rd_en;
    wire [width-1:0] dout;
    wire empty;

    fifo #(
        .depth(depth),
        .width(width)
    ) single_clock_fifo (
        .rst(rst),
        .wr_clk(clk),
        .wr_en(wr_en),
        .din(din),
        .full(full),
        .rd_clk(clk),
        .rd_en(rd_en),
        .dout(dout),
        .empty(empty)
    );

    initial begin : clock
        clk = 1'b0;
        forever begin
            #5 clk = ~clk;
        end
    end

    initial begin : reset
        rst = 1'b1;
        repeat(5)
            @(negedge clk);
        rst = 1'b0;
    end
    
    integer i;
    initial begin : testbench
        wr_en = 1'b0;
        din = 8'h00;
        rd_en = 1'b0;

        wait(rst == 1'b0);
        wr_en = 1'b1;

        for(i=0; i<depth; i=i+1) begin
            din = i + 1;
            @(negedge clk);
        end

        wr_en = 1'b0;

        @(negedge clk);
        @(negedge clk);

        rd_en = 1'b1;

        repeat(8)
            @(negedge clk);

        rd_en = 1'b0;

    end


endmodule

