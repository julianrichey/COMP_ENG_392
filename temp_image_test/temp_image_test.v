`timescale 1 ps / 1 ps

module temp_image_test();

    localparam integer bmp_width = 720;
    localparam integer bmp_height = 540;
    localparam integer bmp_header_size = 54;
    localparam integer bmp_data_size = bmp_width*bmp_height*3; //1 byte for each of rbg

    integer in_file, out_file, i;

    reg [7:0] bmp_header [0:bmp_header_size-1];
    reg [7:0] bmp_data [0:bmp_data_size-1];

    reg [7:0] pixel;

    reg [7:0] grayscale_data [0:bmp_data_size-1];

    initial begin
        in_file = $fopen("copper_720_540.bmp", "rb");
        out_file = $fopen("test_output.bmp", "wb");

        //$fread( mem, fd, start, count)
        //start: first element in memory to be loaded
        //count: # of elements in memory to be loaded
        $fread(bmp_header, in_file, 0, bmp_header_size);
        $fread(bmp_data, in_file, bmp_header_size, bmp_data_size);

        for (i=0; i<bmp_header_size; i=i+1) begin
            $fwrite(out_file, "%c", bmp_header[i]);
        end

        for (i=0; i<bmp_data_size; i=i+3) begin
            pixel = ({2'b00, bmp_data[i+0]} + {2'b00, bmp_data[i+1]} + {2'b00, bmp_data[i+2]}) / 3;
            grayscale_data[i+0] = pixel;
            grayscale_data[i+1] = pixel;
            grayscale_data[i+2] = pixel;
        end

        for (i=0; i<bmp_data_size; i=i+1) begin
            $fwrite(out_file, "%c", grayscale_data[i]);
        end

        $fclose(in_file);
        $fclose(out_file);
        $stop;
    end
    
endmodule
