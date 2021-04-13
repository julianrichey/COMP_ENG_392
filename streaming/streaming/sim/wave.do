
add wave -noupdate -group dut_testbench
add wave -noupdate -group dut_testbench -radix hexadecimal /dut_testbench/*

add wave -noupdate -group dut_testbench/dut_system_inst
add wave -noupdate -group dut_testbench/dut_system_inst -radix hexadecimal /dut_testbench/dut_system_inst/*

add wave -noupdate -group dut_testbench/dut_system_inst/dut_inst
add wave -noupdate -group dut_testbench/dut_system_inst/dut_inst -radix hexadecimal /dut_testbench/dut_system_inst/dut_inst/*

add wave -noupdate -group dut_testbench/dut_system_inst/fifo_in_inst
add wave -noupdate -group dut_testbench/dut_system_inst/fifo_in_inst -radix hexadecimal /dut_testbench/dut_system_inst/fifo_in_inst/*

add wave -noupdate -group dut_testbench/dut_system_inst/fifo_out_inst
add wave -noupdate -group dut_testbench/dut_system_inst/fifo_out_inst -radix hexadecimal /dut_testbench/dut_system_inst/fifo_out_inst/*
