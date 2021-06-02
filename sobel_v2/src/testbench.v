`timescale 1 ns / 1 ns

module dut_testbench();

    //dut_system rearranges itself according to these
    localparam USE_GAUSSIAN = 1'b1;
    localparam USE_SOBEL = 1'b1;

    //first fifo
    localparam integer RGB_DWIDTH = 8 * 3;

    //all other fifos
    localparam integer DWIDTH = 8;
    localparam integer BUFFER = 16;
    
    localparam [20*8-1:0] name = "tiny";

    localparam [20*8-1:0] fifo_in_name = {name,".bmp"};
    localparam integer IMG_WIDTH = (name == "tiny") ? 64 : 720;
    localparam integer IMG_HEIGHT = (name == "tiny") ? 32 : 540;

    localparam [60*8-1:0] fifo_out_name = (USE_GAUSSIAN == 1'b0) ?
                                          ((USE_SOBEL == 1'b0) ? {name,"_grayscale.bmp"} : {name,"_sobel.bmp"}) :
                                          ((USE_SOBEL == 1'b0) ? {name,"_gaussian.bmp"} : {name,"_gaussian_sobel.bmp"});
    localparam [60*8-1:0] groundtruth_name = (USE_GAUSSIAN == 1'b0) ?
                                             ((USE_SOBEL == 1'b0) ? {name,"_grayscale_gt.bmp"} : {name,"_sobel_gt.bmp"}) :
                                             ((USE_SOBEL == 1'b0) ? {name,"_gaussian_gt.bmp"} : {name,"_gaussian_sobel_gt.bmp"});


    // localparam integer IMG_WIDTH = 720;
    // localparam integer IMG_HEIGHT = 540;
    // parameter [27*8-1:0] fifo_in_name = "brooklyn_bridge_720_540.bmp";
    // parameter [25*8-1:0] fifo_out_name = "brooklyn_bridge_sobel.bmp";

    //parameter [119:0] tb_fifo_out_name = "tb_fifo_out.txt";


    localparam integer bmp_header_size = 54;
    localparam integer bytes_per_pixel = 3;
    localparam integer bmp_data_size = IMG_WIDTH*IMG_HEIGHT*bytes_per_pixel+87; //between 87 and 88...

    parameter [63:0] clock_period = 100;

    reg clock = 1'b1;
    reg reset = 1'b0;
    reg hold_clock = 1'b0;
    
    reg [RGB_DWIDTH-1:0] fifo_in_din = 'sh0;
    wire fifo_in_full;
    reg fifo_in_wr_en = 1'sh0;
    reg fifo_in_write_done = 1'sh0;

    wire [DWIDTH-1:0] fifo_out_dout;
    wire fifo_out_empty;
    reg fifo_out_rd_en = 1'sh0;
    reg fifo_out_read_done = 1'sh0;

    integer fifo_out_warnings = 0;
    integer fifo_out_errors = 0;

    integer errors = 0;
    integer warnings = 0;

    //literally just to make modelsim not give warnings
    integer bytes_read_header;
    integer bytes_read_data;
    integer bytes_read_header_groundtruth;
    integer bytes_read_data_groundtruth;

    reg [63:0] start_time = 0;
    reg [63:0] end_time = 0;
    
    integer fifo_in_file;
    integer fifo_in_write_iter = 0;
    reg [RGB_DWIDTH-1:0] fifo_in_data_write;
    
    integer fifo_out_file;
    reg [DWIDTH-1:0] fifo_out_data_read = 'h0;

    integer groundtruth_file;
    reg [RGB_DWIDTH-1:0] groundtruth_data;


    //integer fifo_out_write_iter = 0;
    //integer tb_fifo_out_file;
    integer fifo_out_read_iter = 0;
    //reg [SOBEL_DWIDTH-1:0] fifo_out_data_cmp = 'h0;

    reg [7:0] bmp_header [0:bmp_header_size-1];
    reg [7:0] bmp_header_groundtruth [0:bmp_header_size-1];

    /*function [DWIDTH_OUT-1:0] to_01;
        input reg [DWIDTH_OUT-1:0] val;
        integer i;
        reg [DWIDTH_OUT-1:0] result;
        begin 
            for ( i = 0; i <= DWIDTH_OUT-1; i = i + 1 )
            begin 
                case (val[i])
                    1'b0 : result[i] = 1'b0;
                    1'b1 : result[i] = 1'b1;
                    default : result[i] = 1'b0;
                endcase
            end
            to_01 = result;
        end
    endfunction
    */

    dut_system #(
        .USE_GAUSSIAN(USE_GAUSSIAN),
        .USE_SOBEL(USE_SOBEL),
        .IMG_WIDTH(IMG_WIDTH),
        .IMG_HEIGHT(IMG_HEIGHT),
        .RGB_DWIDTH(RGB_DWIDTH),
        .DWIDTH(DWIDTH),
        .BUFFER(BUFFER)
    ) dut_system_inst (
        .clock(clock),
        .reset(reset),
        .fifo_in_din(fifo_in_din),
        .fifo_in_full(fifo_in_full),
        .fifo_in_wr_en(fifo_in_wr_en),
        .fifo_out_dout(fifo_out_dout),
        .fifo_out_empty(fifo_out_empty),
        .fifo_out_rd_en(fifo_out_rd_en)
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
        
        wait( (fifo_in_write_done == 1'b1) & (fifo_out_read_done == 1'b1) );
        
        end_time = $time;
        $write("@ %0t: Simulation completed in %0t cycles.\n\n", end_time, (end_time - start_time) / clock_period);
                
        $write("\nTotal simulation cycle count: %0t\n\n", $time / clock_period);
        $write("Total warning count: %0d\n", warnings);
        $write("Total error count: %0d\n\n", errors);
        
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
        
        $write("@ %0t: Loading file %s...\n", $time, fifo_in_name);
        fifo_in_file = $fopen(fifo_in_name, "rb");

        //Initial 54 byte read for header
        bytes_read_header = $fread(bmp_header, fifo_in_file, 0, bmp_header_size);

        for (j=0; j<bmp_data_size; j=j+bytes_per_pixel) begin
            wait( clock == 1'b1 );
            wait( clock == 1'b0 );
            if ( fifo_in_full == 1'b1 ) begin
                fifo_in_wr_en <= 1'b0;
                fifo_in_din <= 'h0;
            end else begin
                bytes_read_data = $fread(fifo_in_data_write[23:0], fifo_in_file, bmp_header_size+(j*bytes_per_pixel), bytes_per_pixel);
                fifo_in_din = fifo_in_data_write;
                fifo_in_wr_en <= 1'b1;
            end
        end
        
        $fclose(fifo_in_file);
        
        wait( clock == 1'b0 );
        wait( clock == 1'b1 );
        
        fifo_in_wr_en <= 1'b0;
        fifo_in_write_done <= 1'b1;
        
        wait( clock == 1'b0 );
        wait( clock == 1'b1 );
        
        wait( hold_clock == 1'b1 );
    end

    integer k;

    always 
    begin : fifo_out_file_process
        wait( reset == 1'b1 );
        wait( reset == 1'b0 );
        wait( clock == 1'b0 );
        wait( clock == 1'b1 );
        
        $write("@ %0t: Writing file %s...\n", $time, fifo_out_name);
        fifo_out_file = $fopen(fifo_out_name, "wb");

        for (k=0; k<bmp_header_size; k=k+1) begin
            $fwrite(fifo_out_file, "%c", bmp_header[k]);
        end
        
        // groundtruth_file = $fopen(groundtruth_name, "rb");
        // bytes_read_header_groundtruth = $fread(bmp_header_groundtruth, groundtruth_file, 0, bmp_header_size);


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
                

                // bytes_read_data_groundtruth = $fread(groundtruth_data[23:0], groundtruth_file, bmp_header_size+(k*bytes_per_pixel), bytes_per_pixel);
                // if (groundtruth_data != {3{fifo_out_data_read}}) begin
                //     $write("@ %0t: %s(%0d): ERROR: %x != %x for 'fifo_out'.\n", $time, groundtruth_name, fifo_out_read_iter + 1, {3{fifo_out_data_read}}, groundtruth_data);
                //     errors = errors + 1;

                //     $fwrite(fifo_out_file, "%c%c%c", (fifo_out_data_read | 8'hFF), (fifo_out_data_read | 8'hFF), (fifo_out_data_read | 8'hFF)); //24'hFFFFFF);
                // end else begin
                    $fwrite(fifo_out_file, "%c%c%c", fifo_out_data_read, fifo_out_data_read, fifo_out_data_read);
                // end
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
    end

endmodule
