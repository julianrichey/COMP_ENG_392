
add wave -noupdate -group dut_testbench
add wave -noupdate -group dut_testbench -radix hexadecimal /dut_testbench/*

add wave -noupdate -group dut_testbench/dut_system_inst
add wave -noupdate -group dut_testbench/dut_system_inst -radix hexadecimal /dut_testbench/dut_system_inst/*

add wave -noupdate -group dut_testbench/dut_system_inst/fifo_rgb
add wave -noupdate -group dut_testbench/dut_system_inst/fifo_rgb -radix hexadecimal /dut_testbench/dut_system_inst/fifo_rgb/*

add wave -noupdate -group dut_testbench/dut_system_inst/grayscale_0
add wave -noupdate -group dut_testbench/dut_system_inst/grayscale_0 -radix hexadecimal /dut_testbench/dut_system_inst/grayscale_0/*

add wave -noupdate -group dut_testbench/dut_system_inst/fifo_grayscale
add wave -noupdate -group dut_testbench/dut_system_inst/fifo_grayscale -radix hexadecimal /dut_testbench/dut_system_inst/fifo_grayscale/*


    #add wave -noupdate -group dut_testbench/dut_system_inst/gaussian_0
    #add wave -noupdate -group dut_testbench/dut_system_inst/gaussian_0 -radix hexadecimal /dut_testbench/dut_system_inst/genblk1/gaussian_0/*

    #add wave -noupdate -group dut_testbench/dut_system_inst/gaussian_0/op_gaussian_0
    #add wave -noupdate -group dut_testbench/dut_system_inst/gaussian_0/op_gaussian_0 -radix hexadecimal /dut_testbench/dut_system_inst/genblk1/gaussian_0/genblk1/op_gaussian_0/*

    #add wave -noupdate -group dut_testbench/dut_system_inst/genblk1/fifo_gaussian
    #add wave -noupdate -group dut_testbench/dut_system_inst/genblk1/fifo_gaussian -radix hexadecimal /dut_testbench/dut_system_inst/genblk1/fifo_gaussian/*

add wave -noupdate -group dut_testbench/dut_system_inst/genblk1/sobel_0
add wave -noupdate -group dut_testbench/dut_system_inst/genblk1/sobel_0 -radix hexadecimal /dut_testbench/dut_system_inst/genblk1/sobel_0/*

add wave -noupdate -group dut_testbench/dut_system_inst/genblk1/sobel_0/op_sobel_0
add wave -noupdate -group dut_testbench/dut_system_inst/genblk1/sobel_0/op_sobel_0 -radix hexadecimal /dut_testbench/dut_system_inst/genblk1/sobel_0/genblk1/op_sobel_0/*

add wave -noupdate -group dut_testbench/dut_system_inst/fifo_sobel
add wave -noupdate -group dut_testbench/dut_system_inst/fifo_sobel -radix hexadecimal /dut_testbench/dut_system_inst/fifo_sobel/*

