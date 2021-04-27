
add wave -noupdate -group dut_testbench
add wave -noupdate -group dut_testbench -radix hexadecimal /dut_testbench/*

add wave -noupdate -group dut_testbench/dut_system_inst
add wave -noupdate -group dut_testbench/dut_system_inst -radix hexadecimal /dut_testbench/dut_system_inst/*

add wave -noupdate -group dut_testbench/dut_system_inst/grayscale_0
add wave -noupdate -group dut_testbench/dut_system_inst/grayscale_0 -radix hexadecimal /dut_testbench/dut_system_inst/grayscale_0/*

add wave -noupdate -group dut_testbench/dut_system_inst/fifo_0
add wave -noupdate -group dut_testbench/dut_system_inst/fifo_0 -radix hexadecimal /dut_testbench/dut_system_inst/fifo_0/*

add wave -noupdate -group dut_testbench/dut_system_inst/fifo_1
add wave -noupdate -group dut_testbench/dut_system_inst/fifo_1 -radix hexadecimal /dut_testbench/dut_system_inst/fifo_1/*
