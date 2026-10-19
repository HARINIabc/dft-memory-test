# DFT and Memory Test Exercise

Starting point for adding DFT (design for test) to digital blocks, using open-source tools.

## 1. Scan insertion on an RTL black box (8-bit counter)

- Tools: Fault 0.7.0 (Docker), Yosys, Icarus Verilog 12.0, osu035 cell library
- Flow: RTL -> synthesis -> scan chain insertion -> cut netlist -> fault simulation
- Synthesized netlist: 36 cells (8 flops, 28 gates)
- Scan chain: 8 internal + 9 boundary = 17 cells, verified in simulation
- Fault simulation: 118 fault sites, 96.19% stuck-at coverage
- Note: rst_n was held inactive during test generation, so the reset path is not exercised

## 2. Memory test (March C- MBIST)

- 16x8 SRAM model with an optional injected stuck-at-0 fault (sram.v)
- March C- controller with start/done/fail signals (mbist.v)
- Testbench runs a good memory and a faulty memory side by side (mbist_tb.v)
- Result: good memory fail=0, faulty memory fail=1 (fault detected)

## Limitations

- The MBIST is RTL only; it is not yet synthesized or connected to scan/JTAG
- Only a stuck-at-0 fault on one bit has been tested so far

## Files

- counter.v, counter_tb.v: test design and testbench
- sram.v, mbist.v, mbist_tb.v: memory model and MBIST
- Netlists/: synthesized, scan-chained and cut netlists, and test vectors

## How to run the MBIST simulation

    iverilog -o mbist_sim sram.v mbist.v mbist_tb.v
    vvp mbist_sim

Expected output:

    Good memory:   done=1 fail=0 (expect fail=0)
    Faulty memory: done=1 fail=1 (expect fail=1)
