
setenv LMC_TIMEUNIT -9
vlib work
vmap work work

vlog -work work "../src/fifo.v"
vlog -work work "../src/grayscale.v"
vlog -work work "../src/sobel.v"
vlog -work work "../src/dut_system.v"
vlog -work work "../src/testbench.v"

vsim +notimingchecks -L work work.dut_testbench -wlf testbench.wlf

do wave.do

run -all

--quit

