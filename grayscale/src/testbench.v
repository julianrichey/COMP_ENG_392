

`timescale 1 ns / 1 ns

module dut_testbench();
	parameter [63:0] clock_period = 100;
    
	parameter [18*8-1:0] fifo_in_name = "copper_720_540.bmp";
    
	parameter [20*8-1:0] fifo_out_name = "copper_grayscale.bmp";
	parameter [6*8-1:0] tb_fifo_out_name = "gs.bmp";
    
	localparam integer BUFFER_SIZE = 32;
    localparam integer DWIDTH = 8*3;

	reg clock = 1'b1;
	reg reset = 1'b0;
	reg hold_clock = 1'b0;
    
	reg [DWIDTH-1:0] fifo_in_din = 'sh0;
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

	reg [63:0] start_time = 0;
	reg [63:0] end_time = 0;
    
	integer fifo_in_file;
	integer fifo_in_write_iter = 0;
	reg [DWIDTH-1:0] fifo_in_data_write;
    
	integer fifo_out_file;
	integer fifo_out_write_iter = 0;
	integer tb_fifo_out_file;
	integer fifo_out_read_iter = 0;
	reg [DWIDTH-1:0] fifo_out_data_read = 'h0;
	reg [DWIDTH-1:0] fifo_out_data_cmp = 'h0;

	localparam integer bmp_width = 720;
    localparam integer bmp_height = 540;
    localparam integer bmp_header_size = 54;
    localparam integer bmp_data_size = bmp_width*bmp_height*3; //1 byte for each of rbg
	localparam integer increment = DWIDTH / 8;

	reg [7:0] bmp_header [0:bmp_header_size-1];

	function [DWIDTH-1:0] to_01;
		input reg [DWIDTH-1:0] val;
		integer i;
		reg [DWIDTH-1:0] result;
		begin 
			for ( i = 0; i <= DWIDTH-1; i = i + 1 )
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

	dut_system
    #(.FIFO_DATA_WIDTH(DWIDTH),
      .FIFO_BUFFER_SIZE(BUFFER_SIZE))    
	dut_system_inst
	(
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

		//Initial Read that reads all of the BMP header data(Not sure how we know the BMP_Header_Size though   -robert)
		//can also do this as follows:
		//bmp header is always 14 bytes
		//$fread(bmp_header,fifo_in_file,0,14)
		//byte 10 tells us
		$fread(bmp_header, fifo_in_file, 0, bmp_header_size);

		for (j=0; j<bmp_data_size; j=j+increment) begin
            wait( clock == 1'b1 );
            wait( clock == 1'b0 );
            if ( fifo_in_full == 1'b1 ) begin
                fifo_in_wr_en <= 1'b0;
                fifo_in_din <= 'h0;
            end else begin
				//this is formatted as follows:
				//fread(reg_we_are_writing_data_to,filename_we_get_data_from,Start_location_of_data_in_file,How_much_data_we_are_reading)
				$fread(fifo_in_data_write, fifo_in_file, bmp_header_size+(j*increment), increment);
                fifo_in_wr_en <= 1'b1;
                fifo_in_din <= fifo_in_data_write;
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
	integer ww;

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

		for (k=0; k<bmp_data_size; k=k+increment) begin
            wait( clock == 1'b1 );
            wait( clock == 1'b0 );
            if ( fifo_out_empty == 1'b1 ) begin
                fifo_out_rd_en <= 1'b0;
                fifo_out_data_read = 'h0;
            end else begin
                fifo_out_rd_en <= 1'b1;
                fifo_out_data_read = fifo_out_dout;
				$fwrite(fifo_out_file, "%c", fifo_out_data_read[23:16]); 
				$fwrite(fifo_out_file, "%c", fifo_out_data_read[15:8]); 
				$fwrite(fifo_out_file, "%c", fifo_out_data_read[7:0]);
			end
		end

		//Somewhere, DUT is somehow losing track of a few pixels. These
		//	are temporary writes just to get the correct bmp size so that
		//	it can be viewed. 
		//code to allow us to view bmp file(any data that gets transferred)
		
		for (ww = 0; ww<600000;ww=ww + 1) begin
			$fwrite(fifo_out_file, "%c", 8'hFF);
		
		end
		



//Code from lecture 4/14/21 to transfer data between two files
		/*
		$write("@ %0t: Loading file %s...\n", $time, fifo_out_name);
		fifo_out_file = $fopen(fifo_in_name, "rb");
		

		$fread(bmp_header, fifo_out_file, 0, bmp_header_size);

		$write("@ %0t: Writing file %s...\n", $time, tb_fifo_out_name);
		tb_fifo_out_file = $fopen(tb_fifo_out_name, "wb");

		for (k=0; k<bmp_header_size; k=k+1) begin
            $fwrite(tb_fifo_out_file, "%c", bmp_header[k]);
        end
		

		while ( ! $feof(fifo_out_file) ) begin
			$fscanf(fifo_out_file, "%c", fifo_out_data_read[23:16]);
			$fscanf(fifo_out_file, "%c", fifo_out_data_read[15:8]);
			$fscanf(fifo_out_file, "%c", fifo_out_data_read[7:0]);

			//$fdisplay(fifo_out_data_read);

            $fwrite(tb_fifo_out_file, "%c%c%c", fifo_out_data_read[23:16],fifo_out_data_read[15:8],fifo_out_data_read[7:0]);
			$write("@ %0t: %x\n", $time, fifo_out_data_read);
            //$fwrite(tb_fifo_out_file, "%x\n", fifo_out_data_read);
				
            
        end

*/

//Code to test whether bytes of two files are same DOES NOT WORK
		/*
        while ( ! $feof(fifo_out_file) )
        begin 
            wait( clock == 1'b1 );
            wait( clock == 1'b0 );
            if ( fifo_out_empty == 1'b1 ) begin
                fifo_out_rd_en <= 1'b0;
                fifo_out_data_read = 'h0;
            end
            else begin
                fifo_out_rd_en <= 1'b1;
                fifo_out_data_read = fifo_out_dout;
			
				$fwrite(tb_fifo_out_file, "%c%c%c", fifo_out_data_read[23:16],fifo_out_data_read[15:8],fifo_out_data_read[7:0]);
				
                $fscanf(fifo_out_file, "%c", fifo_out_data_cmp[23:16]);
				$fscanf(fifo_out_file, "%c", fifo_out_data_cmp[15:8]);
				$fscanf(fifo_out_file, "%c", fifo_out_data_cmp[7:0]);
				
                if (to_01(fifo_out_data_read) != to_01(fifo_out_data_cmp)) begin 
                    fifo_out_errors <= fifo_out_errors + 1;
                    $write("@ %0t: %s(%0d): ERROR: %x != %x for 'fifo_out'.\n", $time, tb_fifo_out_name, fifo_out_read_iter + 1, fifo_out_data_read, fifo_out_data_cmp);
                end
				
                fifo_out_read_iter <= fifo_out_read_iter + 1;
				
            end 
		end
		*/
		
		$fclose(tb_fifo_out_file);
		$fclose(fifo_out_file);
		
		wait( clock == 1'b0 );
		wait( clock == 1'b1 );
		
		fifo_out_rd_en <= 1'b0;
		fifo_out_read_done <= 1'b1;
		
		wait( hold_clock == 1'b1 );
	end

endmodule
