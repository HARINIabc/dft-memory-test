#!/usr/bin/env bash
# run_all.sh : regenerates every number in README.md.
# Needs Icarus Verilog 12 and Yosys (tested with 0.33) on Linux.
#   ./run_all.sh [seed]
set -u
cd "$(dirname "$0")"
SEED=${1:-1}
B=$(mktemp -d); trap 'rm -rf "$B"' EXIT

echo "== 2. MBIST (March C-)"
iverilog -o "$B/mbist" sram.v mbist.v mbist_tb.v && vvp -n "$B/mbist" | grep memory

echo; echo "== 3a. wrapper testbench (seed $SEED)"
iverilog -o "$B/wtb" counter.v wrapper/wbr_cell.v wrapper/counter_wrapper.v wrapper/counter_wrapper_tb.v \
  && vvp -n "$B/wtb" +seed="$SEED" | grep 'WRAPPER TB'

echo; echo "== 3b. mutants"
wrapper/run_mutants.sh "$SEED" | tail -1

echo; echo "== 3c. stuck-at fault campaign through the wrapper"
fault/run_faults.sh "$SEED" | tail -4

echo; echo "== 3d. cell counts"
for y in synth synth_wrapper; do
  (cd fault && yosys -q -l "$B/$y.log" "$y.ys" >/dev/null)
  printf '%-15s %s cells\n' "$y" "$(grep 'Number of cells' "$B/$y.log" | tail -1 | awk '{print $4}')"
done
