
add wave -noupdate -group dut_testbench
add wave -noupdate -group dut_testbench -radix hexadecimal /dut_testbench/*

add wave -noupdate -group dut_testbench/dut_system_inst
add wave -noupdate -group dut_testbench/dut_system_inst -radix hexadecimal /dut_testbench/dut_system_inst/*

add wave -noupdate -group dut_testbench/dut_system_inst/fifo_in
add wave -noupdate -group dut_testbench/dut_system_inst/fifo_in -radix hexadecimal /dut_testbench/dut_system_inst/fifo_in/*

add wave -noupdate -group dut_testbench/dut_system_inst/grayscale_0
add wave -noupdate -group dut_testbench/dut_system_inst/grayscale_0 -radix hexadecimal /dut_testbench/dut_system_inst/grayscale_0/*

#uncomment when USE_GAUSSIAN = 1'b1
    add wave -noupdate -group dut_testbench/dut_system_inst/gaussian_0
    add wave -noupdate -group dut_testbench/dut_system_inst/gaussian_0 -radix hexadecimal /dut_testbench/dut_system_inst/genblk1/gaussian_0/*
    add wave -noupdate -group dut_testbench/dut_system_inst/gaussian_0/op_gaussian_0
    add wave -noupdate -group dut_testbench/dut_system_inst/gaussian_0/op_gaussian_0 -radix hexadecimal /dut_testbench/dut_system_inst/genblk1/gaussian_0/genblk1/op_gaussian_0/*

#uncomment when USE_SOBEL = 1'b1
    #add wave -noupdate -group dut_testbench/dut_system_inst/sobel_0
    #add wave -noupdate -group dut_testbench/dut_system_inst/sobel_0 -radix hexadecimal /dut_testbench/dut_system_inst/genblk2/sobel_0/*
    #add wave -noupdate -group dut_testbench/dut_system_inst/sobel_0/op_sobel_0
    #add wave -noupdate -group dut_testbench/dut_system_inst/sobel_0/op_sobel_0 -radix hexadecimal /dut_testbench/dut_system_inst/genblk2/sobel_0/genblk1/op_sobel_0/*




