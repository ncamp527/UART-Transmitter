# This file is public domain, it can be freely copied without restrictions.
# SPDX-License-Identifier: CC0-1.0

# Makefile

# The simulator we want to run our tests with.
SIM = icarus

# The top-level language of the design (verilog or vhdl).
TOPLEVEL_LANG = verilog

# List of Verilog source files.
VERILOG_SOURCES = $(RTL)
RTL = uart_tx.sv

# The name of the toplevel module/entity in your design.
COCOTB_TOPLEVEL = uart_tx

# The Python modules which contain your testcases.
# The current directory is included in the Python path,
# so you can just specify the module name without the .py extension.
COCOTB_TEST_MODULES = uart_tests

# Enable waveform generation.
WAVES = 1

# Includes cocotb's Makefiles which define the build and simulation flows for each supported simulator.
# This must be included *after* all of the variables above are defined.
include $(shell cocotb-config --makefiles)/Makefile.sim

OSS_CAD = /c/Users/ncamp/oss-cad-suite
OSS_ENV = PATH="$(OSS_CAD)/bin:$(OSS_CAD)/lib:$$PATH"

.PHONY: lint waves

lint:
	$(OSS_ENV) VERILATOR_ROOT="C:/Users/ncamp/oss-cad-suite/share/verilator" verilator_bin --lint-only -Wall --top-module $(COCOTB_TOPLEVEL) $(RTL)

waves:
	$(OSS_ENV) gtkwave sim_build/$(COCOTB_TOPLEVEL).fst