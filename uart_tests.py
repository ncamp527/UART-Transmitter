from __future__ import annotations
from collections import deque

import cocotb, secrets, random
from cocotb.clock import Clock
from cocotb.triggers import RisingEdge, FallingEdge

async def reset(dut):
    # set initial values
    dut.tx_start.value = 0
    dut.tx_data.value  = 0

    # keep reset signal high for 3 clock ticks
    dut.rst.value = 1
    for _ in range(3):
        await RisingEdge(dut.clk)
    dut.rst.value = 0

async def output(dut):
    await FallingEdge(dut.tx) # state = start
    bits, durations = [], []
    clks_per_bit = int(dut.CLK_FREQ.value) // int(dut.BAUD_RATE.value)

    for _ in range(10):       # start, byte, stop
        samples = []
        for _ in range(clks_per_bit):
            await RisingEdge(dut.clk)
            samples.append(dut.tx.value)

        value = samples[clks_per_bit // 2]
        bits.append(value)
        durations.append(samples.count(value))

    return bits, durations

async def check_output(dut, ob_bits, ob_durs, input):
    assert ob_bits[0] == 0, (
        f"expected: start bit = 0, got start bit = {ob_bits[0]}"
    )

    ob_byte = sum(b << i for i, b in enumerate(ob_bits[1:9]))
    assert ob_byte == input, (
        f"output expected: {input:#02x}, "
        f"\nactual: {ob_byte:#02x}"
    )

    assert ob_bits[-1] == 1, (
        f"expected: end bit = 1, got end bit = {ob_bits[-1]}"
    )

    clks_per_bit = int(dut.CLK_FREQ.value) // int(dut.BAUD_RATE.value)
    for i in range(len(ob_durs)):
        assert ob_durs[i] == clks_per_bit, (
            f"expected: duration = {clks_per_bit}, got duration = {ob_durs[i]}"
        )


# test_idle
@cocotb.test
async def test_idle(dut):
    Clock(dut.clk, 20, "ns").start()
    await reset(dut)

    for _ in range(5):
        await FallingEdge(dut.clk)

    assert ((int(dut.tx.value) == 1)
        and (int(dut.tx_busy.value) == 0)
        and (int(dut.tx_done.value) == 0)), (
        f"expected:"
        f"\ntx = 1, got tx = {int(dut.tx.value)}"
        f"\ntx_busy = 0, got tx = {int(dut.tx_busy.value)}"
        f"\ntx_done = 0, got tx = {int(dut.tx_done.value)}"
    )

# test_byte
@cocotb.test
async def test_byte(dut):
    Clock(dut.clk, 20, "ns").start()
    for _ in range(50000):
        await reset(dut)

        await FallingEdge(dut.clk)
        expvalues = secrets.randbits(8)
        actvalues = []

        dut.tx_start.value = 1
        dut.tx_data.value  = expvalues


# end test_byte