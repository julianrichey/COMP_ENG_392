setenv LMC_TIMEUNIT -9
vlib work
vmap work work

vlog -work work "../src/bram.v"
vlog -work work "../src/testbench_bram.v"

vsim +notimingchecks -L work work.testbench_bram -wlf testbench.wlf

do wave3.do

run -all

quit

