# DFT and Memory Test Exercise

Starting point for adding DFT (design for test) to digital blocks, using open-source tools.

## 1. Scan insertion on an 8-bit counter

- Tools: Fault 0.7.0 (Docker), Yosys, Icarus Verilog 12.0, osu035 cell library
- Flow: RTL -> synthesis -> scan chain insertion -> cut netlist -> fault simulation
- Synthesized netlist: 36 cells (8 flops, 28 gates)
- Scan chain: 8 internal + 9 boundary = 17 cells, verified in simulation
- Fault simulation: 118 fault sites, 96.19% stuck-at coverage
- Note: rst_n was held inactive during test generation, so the reset path is not exercised
- This flow looks inside the counter (its flops become scan flops), so it is white-box DFT.

## 2. Memory test (March C- MBIST)

- 16x8 SRAM model with an optional injected stuck-at-0 fault (sram.v)
- March C- controller with start/done/fail signals (mbist.v)
- Testbench runs a good memory and a faulty memory side by side (mbist_tb.v)
- Result: good memory fail=0, faulty memory fail=1 (fault detected)
- sram.v was missing from the first commit. It was recreated from the compiled
  mbist_sim (same ports, parameters and behaviour) and gives identical output,
  including the same finish time (1645).

## 3. Black-box DFT: IEEE 1500-style test wrapper (8-bit counter)

The counter is treated as a black box: counter.v is not changed, and every test
reaches it only through its pins. A wrapper around it adds:

- Wrapper boundary register (WBR): one cell per core pin. 2 input cells (rst_n, en)
  and 8 output cells (count), 10 in total. Each cell is a shift flop plus an
  update flop, so values stay steady while the chain shifts.
- Wrapper instruction register (WIR), 2 bits: WS_BYPASS (normal operation),
  WS_INTEST (test the core) and WS_EXTEST (test the logic around the core).
- Wrapper bypass register (WBY): one flop, so a chain of wrapped blocks stays short.
- Wrapper serial port: wrck, wrstn, selectwir, shiftwr, capturewr, updatewr, wsi, wso.
- No clocks are generated or gated in the RTL; clk and wrck are both inputs.

Why this matters for IMC: an in-memory-computing macro is analog inside and cannot
be scan-inserted, but the same wrapper can sit on its digital boundary, giving
controllability and observability without touching the analog core.

Results (Icarus Verilog 12.0, Yosys 0.33):

| Check | Result |
|---|---|
| Wrapper testbench (functional, WIR, WBY, chain flush, INTEST directed + 300 random, EXTEST) | PASS, 370 checks, seeds 1, 7, 42, 999 |
| Mutants (8 broken counters, 5 broken wrappers) | 13 / 13 caught |
| Stuck-at faults on the synthesised counter, tested only through the wrapper (INTEST) | 78 / 78 detected, 100%, seeds 1, 7, 42 |
| Core alone (2-input gates + plain D flops) | 37 cells (8 flops, 29 gates) |
| Core + wrapper | 128 cells (33 flops) |

Directed INTEST includes reset in the middle of counting, hold, and the 255 -> 0
wrap, so the reset path that section 1 left out is tested here.

## Limitations

- The MBIST is RTL only; it is not yet synthesized or connected to scan/JTAG/the wrapper
- Only a stuck-at-0 fault on one bit has been tested so far in the memory
- Section 3's coverage is not directly comparable with section 1's: different cell
  sets (Yosys 2-input gates vs osu035) and a different fault list (78 stuck-at faults
  on nets, i.e. stems only, vs 118 sites from Fault). Branch (pin) faults are not modelled.
- Black-box testing of a sequential core needs functional sequences: about 7,000 wrck
  and 6,200 clk cycles here, against a handful of scan patterns for section 1. Test
  time grows quickly for deeper state machines; this is the cost of not scanning inside.
- The wrapper overhead (91 cells on a 37-cell core) is per pin, so it is large for a
  tiny block and small for a realistic one.
- Stuck-at only; no transition (at-speed) faults yet.

## Files

- counter.v, counter_tb.v: test design and testbench
- sram.v, mbist.v, mbist_tb.v: memory model and MBIST
- counter.nl.v, counter.chained.v, counter.cut.v, counter.cut.v.tv.*: section 1
  netlists (synthesised, scan-chained, cut) and test vectors from Fault
- wrapper/wbr_cell.v, wrapper/counter_wrapper.v: the IEEE 1500-style wrapper
- wrapper/counter_wrapper_tb.v: self-checking wrapper testbench (plain Verilog)
- wrapper/run_mutants.sh: breaks the design on purpose; every mutant must FAIL
- fault/synth.ys, fault/synth_wrapper.ys: Yosys scripts for the core and the wrapped core
- fault/run_faults.sh: stuck-at fault campaign through the wrapper, writes fault/faults.csv
- run_all.sh: regenerates every number in sections 2 and 3

## How to run

Everything (needs Icarus Verilog 12 and Yosys):

    ./run_all.sh 1

MBIST only:

    iverilog -o mbist_sim sram.v mbist.v mbist_tb.v
    vvp mbist_sim

Expected output:

    Good memory:   done=1 fail=0 (expect fail=0)
    Faulty memory: done=1 fail=1 (expect fail=1)

Wrapper testbench only (the last line is PASS or FAIL):

    iverilog -o wtb counter.v wrapper/wbr_cell.v wrapper/counter_wrapper.v wrapper/counter_wrapper_tb.v
    vvp wtb +seed=7
