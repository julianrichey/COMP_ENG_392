setenv LMC_TIMEUNIT -9
vlib work
vmap work work

vlog -work work "../src/fifo.v"
vlog -work work "../src/bram.v"
vlog -work work "../src/softmax.v"
vlog -work work "../src/testbench_softmax.v"

vsim +notimingchecks -L work work.testbench_softmax -wlf testbench.wlf

do wave4.do

run -all

quit

