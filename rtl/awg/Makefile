PROJ = awg
VERSION := r0.2
TOP =  awg_top
# Add Windows and Unix support
RM = rm -rf
COPY = cp -a
PATH_SEP = /
ifeq ($(OS),Windows_NT)
SHELL = cmd.exe
COPY = copy
RM = del
PATH_SEP = \\
endif

# Add PLL file
PLL_100_FILE = pll_100.v
PLL_12_FILE = pll_12.v

SRC = awg_top.v \
      defines.v \
      state_machine.v \
      top_sans_ftdi.v \
      awg_output.v \
      ../ftdi_245fifo/ftdi_245fifo_top.v \
      ../ftdi_245fifo/ftdi_245fifo_fsm.v \
      ../ftdi_245fifo/fifo_async.v \
      ../ftdi_245fifo/fifo2.v \
      ../ftdi_245fifo/fifo4.v \
      ../ftdi_245fifo/resetn_sync.v \
      ../ftdi_245fifo/axi_stream_assert.v \
      ../ftdi_245fifo/axi_stream_downsizing.v \
      ../ftdi_245fifo/axi_stream_resizing.v \
      ../ftdi_245fifo/axi_stream_packing.v \
      ../ftdi_245fifo/axi_stream_upsizing.v \
      ../ftdi_245fifo/fifo_delay_submit.v \
      $(PLL_100_FILE) \
      $(PLL_12_FILE)

LPF = pins.pcf

all: $(PROJ).bit

# PLL generation
$(PLL_100_FILE):
	ecppll -i 16 -o 100 -f $@ -n pll_100

$(PLL_12_FILE):
	ecppll -i 16 -o 12 -f $@ -n pll_12

$(PROJ).json: $(SRC) $(PLL_100_FILE) $(PLL_12_FILE )
	yosys -Wall -Werror -p "synth_ecp5 -top $(TOP) -json $@" $(SRC) 

$(PROJ)_out.config: $(PROJ).json $(LPF)
	nextpnr-ecp5 --45k --package CABGA256 --speed 7 --json $< --textcfg $@ --lpf $(LPF)

$(PROJ).bit: $(PROJ)_out.config
	ecppack --compress --svf $(PROJ).svf $< $@

$(PROJ).svf: $(PROJ).bit

.PHONY: prog
prog: $(PROJ).bit
	ecpdap program --freq 4M $<

# Simulation variables
SIM_SRC = defines.v test_data_generation.v state_machine.v top_sans_ftdi.v awg_output.v top_sans_ftdi_tb.v

.PHONY: sim
TESTBENCH_DEFINE = -DTESTBENCH
sim: top_sans_ftdi_tb.vcd
top_sans_ftdi_tb.vcd: $(SIM_SRC)
# is this python bad practice? Yes. oh well.
	python ../../python/gen_test_data.py
	iverilog -Wall -o top_sans_ftdi_tb.vvp $(TESTBENCH_DEFINE) $(SIM_SRC) test_data.gen.v
	vvp top_sans_ftdi_tb.vvp

.PHONY: view
view: top_sans_ftdi_tb.vcd
	gtkwave top_sans_ftdi_tb.vcd &

.PHONY: clean
clean:
	$(RM) *.svf *.bit *.config *.json *.ys *.dfu $(PLL_100_FILE) $(PLL_12_FILE) *.vcd *.vvp *.gen.v

.PHONY: timing_report
timing_report: $(PROJ)_out.config
	$(RM) timing_report.txt
	ecppack --input $< --textcfg timing_report.txt --verbose 2>&1

# DFU-specific targets (if still needed)
$(PROJ).dfu : $(PROJ).bit
	$(COPY) $< $@
	dfu-suffix -v 1209 -p 5af0 -a $@

.PHONY: dfu
dfu: $(PROJ).dfu
	dfu-util -D $<