`timescale 1 ns / 1 ns

module testbench_softmax();


    localparam integer DWIDTH_IN = 16;
    localparam integer DWIDTH_OUT = 16;

    localparam integer BUFFER = 100;

    parameter [63:0] clock_period = 100;

    reg clock = 1'b1;
    reg reset = 1'b0;
    reg hold_clock = 1'b0;
    reg fifo_out_read_done = 1'b0;
    reg data_in_done = 1'b0;
    
    reg [DWIDTH_IN-1:0] din = 'sh0;
    wire out_wr_en;
    wire [DWIDTH_OUT-1:0] softmax_dout, fifo_in_dout, final_vals;
    wire in_empty;
    wire in_rd_en,out_full;
    reg fifo_in_wr_en, out_rd_en;

//Test values we randomly generate here
    localparam[15:0] random_test_vals[0:99] = '{16'h1b99, 16'h1437, 16'h17a8, 16'h1630, 16'h0f23, 16'h0a4f, 16'h084b, 16'h190c, 16'h0d9a, 16'h21c1, 16'h02c0, 
    16'h1065, 16'h2333, 16'h0cc7, 16'h2739, 16'h0366, 16'h244e, 16'h0419, 16'h24e1, 16'h144d, 16'h22e4, 
    16'h0d54, 16'h1bb2, 16'h1647, 16'h0e7a, 16'h0147, 16'h2257, 16'h03f5, 16'h2315, 16'h11f8, 16'h1149, 
    16'h1840, 16'h251d, 16'h1a92, 16'h0fd0, 16'h1189, 16'h1a15, 16'h2527, 16'h25f7, 16'h0c4b, 16'h17db, 
    16'h1f52, 16'h0d85, 16'h2035, 16'h25b0, 16'h02a8, 16'h2248, 16'h2716, 16'h2395, 16'h15cf, 16'h2293, 
    16'h124f, 16'h2002, 16'h22f2, 16'h20df, 16'h076d, 16'h0373, 16'h1986, 16'h095a, 16'h1282, 16'h004b, 
    16'h1966, 16'h10d9, 16'h2625, 16'h0867, 16'h26d4, 16'h0a73, 16'h2248, 16'h1740, 16'h1c4a, 16'h0b70, 
    16'h0cba, 16'h19c2, 16'h2257, 16'h1ac1, 16'h11b9, 16'h023c, 16'h1f19, 16'h17c9, 16'h0415, 16'h0bfb, 
    16'h2607, 16'h1aa0, 16'h25e8, 16'h232d, 16'h1c08, 16'h0f0a, 16'h188a, 16'h2286, 16'h0572, 16'h1196, 
    16'h0afb, 16'h0778, 16'h143f, 16'h16d2, 16'h1ae9, 16'h18f1, 16'h0273, 16'h1604, 16'h168e };


    reg [63:0] start_time = 0;
    reg [63:0] end_time = 0;


    //integer fifo_out_write_iter = 0;
    //integer tb_fifo_out_file;
    integer fifo_out_read_iter = 0;
    //reg [SOBEL_DWIDTH-1:0] fifo_out_data_cmp = 'h0;

    fifo #(
        .FIFO_DATA_WIDTH(DWIDTH_IN),
        .FIFO_BUFFER_SIZE(BUFFER)
    ) fifo_in (
        .rd_clk(clock),
        .wr_clk(clock),
        .reset(reset),

        .wr_en(fifo_in_wr_en),
        .din(din),
        .full(fifo_in_full),

        .rd_en(in_rd_en),
        .dout(fifo_in_dout),
        .empty(in_empty)
    );

//outputs: fifo_in_rd_en, fifo_out-wr_en, fifo_out_din
    softmax #(
        .DWIDTH_IN(DWIDTH_IN),
        .DWIDTH_OUT(DWIDTH_IN),
        .BITS(10)
    ) softmax_inst (
        .clock(clock),
        .reset(reset),
        .fifo_in_rd_en(in_rd_en),
        .fifo_in_dout(fifo_in_dout),
        .fifo_in_empty(in_empty),
        .fifo_out_wr_en(out_wr_en), 
        .fifo_out_din(softmax_dout), 
        .fifo_out_full(out_full)
    );

    fifo #(
        .FIFO_DATA_WIDTH(DWIDTH_IN),
        .FIFO_BUFFER_SIZE(BUFFER)
    ) fifo_out (
        .rd_clk(clock),
        .wr_clk(clock),
        .reset(reset),

        .wr_en(out_wr_en),
        .din(softmax_dout),
        .full(out_full),

        .rd_en(out_rd_en),
        .dout(final_vals),
        .empty(out_empty)
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
        
        wait( (data_in_done == 1'b1) && (fifo_out_read_done == 1'b1));
        
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

        //din <= 16'hbeef;
        //in_empty <= 1'b0;
        //out_full <= 1'b0;
        fifo_in_wr_en <= 1'b0;
        out_rd_en <= 1'b0;

        for (j=0; j<100; j=j+1) begin
            wait( clock == 1'b1 );
            wait( clock == 1'b0 );
            fifo_in_wr_en <= 1'b1;
            din <= random_test_vals[j];
            //fifo_in_wr_en <= 1'b1;
        end

        out_rd_en <= 1'b1;
        
        wait( clock == 1'b0 );
        wait( clock == 1'b1 );


        
        data_in_done <= 1'b1;
        wait( hold_clock == 1'b1 );
    end

    always 
    begin : fifo_out_file_process
        wait( reset == 1'b1 );
        wait( reset == 1'b0 );
        wait( clock == 1'b0 );
        wait( clock == 1'b1 );

        wait( out_empty == 1'b0);
        wait( out_empty == 1'b1);

//wait for a while
        for (j=0; j<300; j=j+1) begin
            wait( clock == 1'b1 );
            wait( clock == 1'b0 );
            fifo_out_read_done <= 1'b0;
        end

        //wait(fully_done == 1'b1);
        #5000;

        //I tried to make the simulation wait for a while but this didn't work so I'ma just wait forever
        fifo_out_read_done <= 1'b1;
        
        /*
        $write("@ %0t: Writing file %s...\n", $time, fifo_out_name);
        fifo_out_file = $fopen(fifo_out_name, "wb");

        for (k=0; k<bmp_header_size; k=k+1) begin
            $fwrite(fifo_out_file, "%c", bmp_header[k]);
        end

        groundtruth_file = $fopen(groundtruth_name, "rb");
        bytes_read_header_groundtruth = $fread(bmp_header_groundtruth, groundtruth_file, 0, bmp_header_size);

        wait( fifo_out_empty == 1'b0);
        
        for (k=0; k<bmp_data_size; k=k+bytes_per_pixel) begin
            wait( clock == 1'b1 );
            wait( clock == 1'b0 );
            if ( fifo_out_empty == 1'b1 ) begin
                fifo_out_rd_en <= 1'b0;
                fifo_out_data_read = 'h0;
            end else begin
                fifo_out_rd_en <= 1'b1;
                fifo_out_data_read = fifo_out_dout;
                $fwrite(fifo_out_file, "%c%c%c", fifo_out_data_read, fifo_out_data_read, fifo_out_data_read);

                bytes_read_data_groundtruth = $fread(groundtruth_data[23:0], groundtruth_file, bmp_header_size+(k*bytes_per_pixel), bytes_per_pixel);
                if (groundtruth_data != {3{fifo_out_data_read}}) begin
                    $write("@ %0t: %s(%0d): ERROR: %x != %x for 'fifo_out'.\n", $time, groundtruth_name, fifo_out_read_iter + 1, {3{fifo_out_data_read}}, groundtruth_data);
                    errors = errors + 1;
                end
                fifo_out_read_iter = fifo_out_read_iter + 1;

            end
        end

        $fclose(fifo_out_file);
        $fclose(groundtruth_file);
        
        wait( clock == 1'b0 );
        wait( clock == 1'b1 );
        
        fifo_out_rd_en <= 1'b0;
        fifo_out_read_done <= 1'b1;
        
        wait( hold_clock == 1'b1 );
        */
    end

endmodule
