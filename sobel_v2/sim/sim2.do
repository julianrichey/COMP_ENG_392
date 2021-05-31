setenv LMC_TIMEUNIT -9
vlib work
vmap work work

vlog -work work "../src/relu.v"
vlog -work work "../src/testbench_relu.v"

vsim +notimingchecks -L work work.testbench_relu -wlf testbench.wlf

do wave2.do

run -all

quit

