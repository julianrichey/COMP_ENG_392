

`timescale 1 ns / 1 ns

module dut_testbench();
	parameter [63:0] clock_period = 100;
    
	parameter [87:0] fifo_in_name = "fifo_in.txt";
	parameter integer fifo_in_buf_size = 32;
    
	parameter [95:0] fifo_out_name = "fifo_out.txt";
	parameter [119:0] tb_fifo_out_name = "tb_fifo_out.txt";
	parameter integer fifo_out_buf_size = 32;
    
    localparam integer DWIDTH = 32;
        
	reg clock = 1'b1;
	reg reset = 1'b0;
	reg hold_clock = 1'b0;
    
	reg [DWIDTH-1:0] fifo_in_din = 32'sh00000000;
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
      .FIFO_BUFFER_SIZE(64))    
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

	always 
	begin : fifo_in_file_process
		wait( reset == 1'b1 );
		wait( reset == 1'b0 );
		wait( clock == 1'b0 );
		wait( clock == 1'b1 );
		
		$write("@ %0t: Loading file %s...\n", $time, fifo_in_name);
		fifo_in_file = $fopen(fifo_in_name, "r");
		
        while ( ! $feof(fifo_in_file) )
        begin 
            wait( clock == 1'b1 );
            wait( clock == 1'b0 );
            if ( fifo_in_full == 1'b1 ) begin
                fifo_in_wr_en <= 1'b0;
                fifo_in_din <= 'h0;
            end
            else begin
                $fscanf(fifo_in_file, "%8x\n", fifo_in_data_write);
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

	always 
	begin : fifo_out_file_process
		wait( reset == 1'b1 );
		wait( reset == 1'b0 );
		wait( clock == 1'b0 );
		wait( clock == 1'b1 );
		
		$write("@ %0t: Loading file %s...\n", $time, fifo_out_name);
		fifo_out_file = $fopen(fifo_out_name, "r");
		
		$write("@ %0t: Writing file %s...\n", $time, tb_fifo_out_name);
		tb_fifo_out_file = $fopen(tb_fifo_out_name, "w");
		
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
			
                $fwrite(tb_fifo_out_file, "%x\n", fifo_out_data_read);
                $fscanf(fifo_out_file, "%8x\n", fifo_out_data_cmp);
                if (to_01(fifo_out_data_read) != to_01(fifo_out_data_cmp)) begin 
                    fifo_out_errors <= fifo_out_errors + 1;
                    $write("@ %0t: %s(%0d): ERROR: %x != %x for 'fifo_out'.\n", $time, tb_fifo_out_name, fifo_out_read_iter + 1, fifo_out_data_read, fifo_out_data_cmp);
                end
                fifo_out_read_iter <= fifo_out_read_iter + 1;
            end 
		end
		
		$fclose(tb_fifo_out_file);
		$fclose(fifo_out_file);
		
		wait( clock == 1'b0 );
		wait( clock == 1'b1 );
		
		fifo_out_rd_en <= 1'b0;
		fifo_out_read_done <= 1'b1;
		
		wait( hold_clock == 1'b1 );
	end

endmodule
