
add wave -noupdate -group dut_testbench
add wave -noupdate -group dut_testbench -radix hexadecimal /dut_testbench/*

add wave -noupdate -group dut_testbench/dut_system_inst
add wave -noupdate -group dut_testbench/dut_system_inst -radix hexadecimal /dut_testbench/dut_system_inst/*

add wave -noupdate -group dut_testbench/dut_system_inst/sobels
add wave -noupdate -group dut_testbench/dut_system_inst/sobels -radix hexadecimal /dut_testbench/dut_system_inst/sobels/*

add wave -noupdate -group dut_testbench/dut_system_inst/grayscales[0]
add wave -noupdate -group dut_testbench/dut_system_inst/grayscales[0] -radix hexadecimal /dut_testbench/dut_system_inst/grayscales[0]/*

add wave -noupdate -group dut_testbench/dut_system_inst/grayscales[1]
add wave -noupdate -group dut_testbench/dut_system_inst/grayscales[1] -radix hexadecimal /dut_testbench/dut_system_inst/grayscales[1]/*

add wave -noupdate -group dut_testbench/dut_system_inst/grayscales[2]
add wave -noupdate -group dut_testbench/dut_system_inst/grayscales[2] -radix hexadecimal /dut_testbench/dut_system_inst/grayscales[2]/*

add wave -noupdate -group dut_testbench/dut_system_inst/fifo_rgb
add wave -noupdate -group dut_testbench/dut_system_inst/fifo_rgb -radix hexadecimal /dut_testbench/dut_system_inst/fifo_rgb/*

add wave -noupdate -group dut_testbench/dut_system_inst/fifo_grayscale
add wave -noupdate -group dut_testbench/dut_system_inst/fifo_grayscale -radix hexadecimal /dut_testbench/dut_system_inst/fifo_grayscale/*

add wave -noupdate -group dut_testbench/dut_system_inst/fifo_sobel
add wave -noupdate -group dut_testbench/dut_system_inst/fifo_sobel -radix hexadecimal /dut_testbench/dut_system_inst/fifo_sobel/*

