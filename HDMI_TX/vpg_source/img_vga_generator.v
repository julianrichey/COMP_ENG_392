
module img_vga_generator(                                    
  input						clk,                
  input						reset_n,                                                
  input			[11:0]	h_total,           
  input			[11:0]	h_sync,           
  input			[11:0]	h_start,             
  input			[11:0]	h_end,                                                    
  input			[11:0]	v_total,           
  input			[11:0]	v_sync,            
  input			[11:0]	v_start,           
  input			[11:0]	v_end, 
  input			[11:0]	v_active_14, 
  input			[11:0]	v_active_24, 
  input			[11:0]	v_active_34, 
  output	reg				vga_hs,             
  output	reg				vga_vs,           
  output	reg				vga_de,
  output	reg	[7:0]		vga_r,
  output	reg	[7:0]		vga_g,
  output	reg	[7:0]		vga_b                                                 
);

//=======================================================
//  Signal declarations
//=======================================================
reg	[11:0]	h_count;
reg	[9:0]		pixel_x;
reg	[11:0]	v_count;
reg [8:0]       pixel_y;
reg				h_act; 
reg				h_act_d;
reg				v_act; 
reg				v_act_d; 
reg				pre_vga_de;
wire				h_max, hs_end, hr_start, hr_end;
wire				v_max, vs_end, vr_start, vr_end;
wire				v_act_14, v_act_24, v_act_34;
reg				boarder;
reg	[3:0]		color_mode;

//=======================================================
//  Structural coding
//=======================================================
assign h_max = h_count == h_total;
assign hs_end = h_count >= h_sync;
assign hr_start = h_count == h_start; 
assign hr_end = h_count == h_end;
assign v_max = v_count == v_total;
assign vs_end = v_count >= v_sync;
assign vr_start = v_count == v_start; 
assign vr_end = v_count == v_end;
assign v_act_14 = v_count == v_active_14; 
assign v_act_24 = v_count == v_active_24; 
assign v_act_34 = v_count == v_active_34;

//horizontal control signals
always @ (posedge clk or negedge reset_n)
	if (!reset_n)
	begin
		h_act_d	<=	1'b0;
		h_count	<=	12'b0;
		pixel_x	<=	10'b0;
		vga_hs	<=	1'b1;
		h_act		<=	1'b0;
	end
	else
	begin
		h_act_d	<=	h_act;

		if (h_max)
			h_count	<=	12'b0;
		else
			h_count	<=	h_count + 12'b1;

		if (h_act_d)
			pixel_x	<=	pixel_x + 10'b1;
		else
			pixel_x	<=	10'b0;

		if (hs_end && !h_max)
			vga_hs	<=	1'b1;
		else
			vga_hs	<=	1'b0;

		if (hr_start)
			h_act		<=	1'b1;
		else if (hr_end)
			h_act		<=	1'b0;
	end

//vertical control signals
always@(posedge clk or negedge reset_n)
	if(!reset_n)
	begin
		v_act_d		<=	1'b0;
		v_count		<=	12'b0;
        pixel_y     <=  9'b0;
		vga_vs		<=	1'b1;
		v_act			<=	1'b0;
		color_mode	<=	4'b0;
	end
	else 
	begin		
		if (h_max)
		begin		  
			v_act_d	  <=	v_act;
		  
			if (v_max)
				v_count	<=	12'b0;
			else
				v_count	<=	v_count + 12'b1;

            if (v_act_d)
                pixel_y	<=	pixel_y + 9'b1;
            else
                pixel_y	<=	9'b0;

			if (vs_end && !v_max)
				vga_vs	<=	1'b1;
			else
				vga_vs	<=	1'b0;

			if (vr_start)
				v_act <=	1'b1;
			else if (vr_end)
				v_act <=	1'b0;

			// if (vr_start)
			// 	color_mode[0] <=	1'b1;
			// else if (v_act_14)
			// 	color_mode[0] <=	1'b0;

			// if (v_act_14)
			// 	color_mode[1] <=	1'b1;
			// else if (v_act_24)
			// 	color_mode[1] <=	1'b0;
		    
			// if (v_act_24)
			// 	color_mode[2] <=	1'b1;
			// else if (v_act_34)
			// 	color_mode[2] <=	1'b0;
		    
			// if (v_act_34)
			// 	color_mode[3] <=	1'b1;
			// else if (vr_end)
			// 	color_mode[3] <=	1'b0;
		end
    end

//(640*480*3+54)/3-1 = 307217
// reg [23:0] ram [0:307217];
// parameter MEM_INIT_FILE = "copper_640_480.mif";

// initial begin
//     $readmemh(MEM_INIT_FILE, ram);
// end


reg [18:0] mem_addr;
wire [23:0] dataout;
altsyncram #(
    .operation_mode("ROM"), //ROM SINGLE_PORT
    .width_a(24),
    .widthad_a(19),
    .numwords_a(307218),
    .output_reg_a("CLOCK0"), //CLOCK0 UNREGISTERED
    .init_file("copper_640_480.mif")
) altsyncram_rom (
    .clock0(clk),
    .address_a(mem_addr),
    .wren_a(1'b0),
    .data_a(24'b0),
    .q_a(dataout)
);

//data[]
//address[]
//wren
//byteena[]
//addressstall
//inclock
//clockena
//rden
//aclr

//q[]
//outclock


//pattern generator and display enable
always @(posedge clk or negedge reset_n)
begin
	if (!reset_n)
	begin
		vga_de		<=	1'b0;
		pre_vga_de	<=	1'b0;
		boarder		<=	1'b0;	
        mem_addr    <= 19'b0;	
	end
	else
	begin
		vga_de		<=	pre_vga_de;
		pre_vga_de	<=	v_act && h_act;
    
		if ((!h_act_d&&h_act) || hr_end || (!v_act_d&&v_act) || vr_end)
			boarder	<=	1'b1;
		else
			boarder	<=	1'b0;   		
		
        mem_addr <= (479 - pixel_y) * 640 + pixel_x + 18; //18 is the header
		if (boarder)
			{vga_r, vga_g, vga_b} <= {8'hFF,8'hFF,8'hFF};
		else
            {vga_r, vga_g, vga_b} <= dataout;
	end
end



// wire [23:0] dataout;
// RAMinit_meminit_jmm RAMinit_meminit_jmm_0 ( 
//     .clock(clk),
//     .dataout(dataout), //24 bits. data at the address specified by ram_address
//     .init(),
//     .init_busy(),
//     .ram_address(), //19 bits
//     .ram_wren() //1'b1 : dataout port data is valid
// );


endmodule