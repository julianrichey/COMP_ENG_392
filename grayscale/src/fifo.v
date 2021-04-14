

`timescale 1 ns / 1 ns

module fifo(rd_clk, wr_clk, reset, rd_en, wr_en, din, dout, full, empty);

    parameter integer FIFO_DATA_WIDTH = 32;
    parameter integer FIFO_BUFFER_SIZE = 32;

    input wire rd_clk;
    input wire wr_clk;
    input wire reset;
    input wire rd_en;
    input wire wr_en;
    input wire [(FIFO_DATA_WIDTH - 1):0] din;
    output reg [(FIFO_DATA_WIDTH - 1):0] dout;
    output wire full;
    output reg empty;

    localparam integer NUM_ELEMENTS = (FIFO_BUFFER_SIZE * 8) / FIFO_DATA_WIDTH;
    localparam integer ADDR_SIZE = ((log2(NUM_ELEMENTS) >= 1) ? log2(NUM_ELEMENTS) : 1) + 1;
    
    reg [(FIFO_DATA_WIDTH - 1):0] fifo_buf [0:(NUM_ELEMENTS - 1)];
    reg [(ADDR_SIZE - 1):0] write_addr;
    reg [(ADDR_SIZE - 1):0] read_addr;
    wire [(ADDR_SIZE - 1):0] write_addr_t;
    wire [(ADDR_SIZE - 1):0] read_addr_t;
    wire full_t;
    wire empty_t;

    function [63:0] to01;
        input reg [63:0] val;
        integer i;
        reg [63:0] result;
        begin 
            for ( i = 0; i <= 63; i = i + 1 )
            begin 
                
                case (val[i])
                    1'b0 : result[i] = 1'b0;

                    1'b1 : result[i] = 1'b1;

                    default : result[i] = 1'b0;

                endcase
            end
            to01 = result;
        end
    endfunction


    function integer log2;
        input integer val;
        integer tmp;
        begin 
            tmp = val;
            for ( log2 = 0; tmp > 1; log2 = log2 + 1 )
            begin 
                tmp = tmp >> 1;
            end
            if ((val != 0) && ((1 << log2) != val)) log2 = log2 + 1;
        end
    endfunction


    always @
    (
        posedge wr_clk
    )
    begin : p_write_buffer
        if (wr_clk == 1'b1) begin 
            if ((wr_en == 1'h1) & (full_t == 1'h0)) begin 
                fifo_buf[write_addr[(ADDR_SIZE - 2):0]] <= din;
            end
        end
    end

    always @
    (
        posedge rd_clk
    )
    begin : p_read_buffer
        if (rd_clk == 1'b1) begin 
            dout <= to01(fifo_buf[read_addr_t[(ADDR_SIZE - 2):0]]);
        end
    end

    always @
    (
        posedge wr_clk, 
        posedge reset
    )
    begin : p_write_addr
        if (reset == 1'h1) begin 
            write_addr <= 'h0;
        end
        else if (wr_clk == 1'b1) begin 
            write_addr <= write_addr_t;
        end
    end

    always @
    (
        posedge rd_clk, 
        posedge reset
    )
    begin : p_read_addr
        if (reset == 1'h1) begin 
            read_addr <= 1'h0;
        end
        else if (rd_clk == 1'b1) begin 
            read_addr <= read_addr_t;
        end
    end

    always @
    (
        posedge rd_clk, 
        posedge reset
    )
    begin : p_empty
        if (reset == 1'b1) begin 
            empty <= 1'h1;
        end
        else if (rd_clk == 1'b1) begin 
            empty <= (write_addr == read_addr_t) ? 1'h1 : 1'h0;
        end
    end
    
    assign full = full_t;
    assign full_t = ((write_addr[(ADDR_SIZE - 2):0] == read_addr[(ADDR_SIZE - 2):0]) & (write_addr[ADDR_SIZE - 1] != read_addr[ADDR_SIZE - 1])) ? 1'h1 : 1'h0;
    assign empty_t = (write_addr == read_addr) ? 1'h1 : 1'h0;
    assign read_addr_t = ((rd_en == 1'h1) & (empty_t == 1'h0)) ? (read_addr + 1'h1) : read_addr;
    assign write_addr_t = ((wr_en == 1'h1) & (full_t == 1'h0)) ? (write_addr + 1'h1) : write_addr;

endmodule
