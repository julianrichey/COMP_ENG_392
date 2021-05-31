`timescale 1 ns / 1 ns

module testbench_bram();


    localparam integer BRAM_BSIZE = 4096;
    localparam integer BRAM_ADDR_W = 13;
    localparam integer BRAM_DWIDTH = 16;

    parameter [63:0] clock_period = 100;

    reg clock = 1'b1;
    reg reset = 1'b0;
    reg hold_clock = 1'b0;
    reg data_in_done = 1'b0;
    
    reg [BRAM_DWIDTH-1:0] din = 'sh0;
    reg wr_en = 1'b0;
    wire [BRAM_DWIDTH-1:0] dout;
    reg [BRAM_ADDR_W-1:0] addr = 'sh0;



    //literally just to make modelsim not give warnings

    reg [63:0] start_time = 0;
    reg [63:0] end_time = 0;


    //integer fifo_out_write_iter = 0;
    //integer tb_fifo_out_file;
    integer fifo_out_read_iter = 0;
    //reg [SOBEL_DWIDTH-1:0] fifo_out_data_cmp = 'h0;



    bram #(
        .BRAM_BUFFER_SIZE(BRAM_BSIZE),
        .BRAM_DATA_WIDTH(BRAM_DWIDTH),
        .BRAM_ADDR_WIDTH(BRAM_ADDR_W)
    ) bram_inst (
        .clock(clock),
        .reset(reset),
        .rd_addr(addr),
        .wr_addr(addr),
        .wr_en(wr_en),
        .din(din),
        .dout(dout)
    );

    always 
    begin : clock_process
        clock <= 1'b1;
        #(clock_period / 2) ;
        clock <= 1'b0;
        #(clock_period / 2) ;
        if (hold_clock == 1'b1) begin 
            $stop;
        end
    end

    always 
    begin : reset_process
        reset <= 1'b0;
        wait( clock == 1'b0 );
        wait( clock == 1'b1 );
        reset <= 1'b1;
        wait( clock == 1'b0 );
        wait( clock == 1'b1 );
        reset <= 1'b0;
        wait( hold_clock == 1'b1 );
        $stop;
    end

    always
    begin : tb_process
        wait( reset == 1'b1 );
        wait( reset == 1'b0 );
        
        wait( clock == 1'b0 );
        wait( clock == 1'b1 );
        
        start_time = $time;
        $write("\n@ %0t: Beginning simulation...\n", start_time);
        
        wait( (data_in_done == 1'b1));
        
        end_time = $time;
        $write("@ %0t: Simulation completed in %0t cycles.\n\n", end_time, (end_time - start_time) / clock_period);
                
        $write("\nTotal simulation cycle count: %0t\n\n", $time / clock_period);
        
        hold_clock <= 1'b1;
        $stop;
    end

    integer j;

    always
    begin : fifo_in_file_process
        wait( reset == 1'b1 );
        wait( reset == 1'b0 );
        wait( clock == 1'b0 );
        wait( clock == 1'b1 );
        
        wait( clock == 1'b0 );
        wait( clock == 1'b1 );

        //wr_en <= 1'b1;
        //din <= 16'hbeef;
        //addr <= 'b0;
        for (j=0; j<5000; j=j+1) begin
            wait( clock == 1'b1 );
            wait( clock == 1'b0 );
            addr <= j % 51;
            din <= j;
            wr_en <= j % 2;
            //fifo_in_wr_en <= 1'b1;
        end
        
        wait( clock == 1'b0 );
        wait( clock == 1'b1 );
        
        data_in_done <= 1'b1;
        wait( hold_clock == 1'b1 );
    end

endmodule
