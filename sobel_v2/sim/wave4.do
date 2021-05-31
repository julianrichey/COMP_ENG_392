
add wave -noupdate -group testbench_softmax
add wave -noupdate -group testbench_softmax -radix hexadecimal /testbench_softmax/*

add wave -noupdate -group testbench_softmax/fifo_in
add wave -noupdate -group testbench_softmax/fifo_in -radix hexadecimal /testbench_softmax/fifo_in/*

add wave -noupdate -group testbench_softmax/fifo_out
add wave -noupdate -group testbench_softmax/fifo_out -radix hexadecimal /testbench_softmax/fifo_out/*
add wave -noupdate -group testbench_softmax/fifo_out -radix hexadecimal /testbench_softmax/fifo_out/q

add wave -noupdate -group testbench_softmax/softmax_inst
add wave -noupdate -group testbench_softmax/softmax_inst -radix hexadecimal /testbench_softmax/softmax_inst/*

add wave -noupdate -group testbench_softmax/softmax_inst/my_mem
add wave -noupdate -group testbench_softmax/softmax_inst/my_mem -radix hexadecimal /testbench_softmax/softmax_inst/my_mem/*
add wave -noupdate -group testbench_softmax/softmax_inst/my_mem -radix hexadecimal /testbench_softmax/softmax_inst/my_mem/mem



