#!/usr/bin/env bash
# run_faults.sh : stuck-at fault campaign on the synthesised counter, tested
# ONLY through the IEEE 1500 wrapper (the black-box view).
#
#  1. synthesise counter.v with Yosys (synth.ys) -> counter_gl.v
#  2. run the wrapper testbench on the fault-free netlist; it must PASS
#  3. for every net in the netlist except clk, force it to 0 and then to 1
#     for the whole simulation; the fault is DETECTED if the testbench FAILs
#  4. write faults.csv and print the coverage
#
# The testbench runs with +intest_only, so the core is reached only through
# the wrapper boundary cells (no direct functional-pin access).
#
#   run from this folder:  ./run_faults.sh [seed]
set -u
cd "$(dirname "$0")"
SEED=${1:-1}
MODE=${MODE:-+intest_only}
SIMCELLS=${SIMCELLS:-/usr/share/yosys/simcells.v}
W=../wrapper
SRC="$W/wbr_cell.v $W/counter_wrapper.v $W/counter_wrapper_tb.v counter_gl.v $SIMCELLS"
TMP=$(mktemp -d); trap 'rm -rf "$TMP"' EXIT

yosys -q -l synth.log synth.ys >/dev/null || { echo "synthesis failed"; exit 1; }

sim() {   # extra iverilog args -> PASS / FAIL / COMPILE-ERROR
    iverilog -o "$TMP/sim" "$@" $SRC 2>/dev/null || { echo COMPILE-ERROR; return; }
    vvp -n "$TMP/sim" +seed="$SEED" $MODE | grep -o 'WRAPPER TB [A-Z]*' | awk '{print $3}'
}

good=$(sim)
echo "fault-free gate-level netlist: $good"
[ "$good" = PASS ] || { echo "the fault-free netlist must PASS first"; exit 1; }

# fault sites: every scalar net, every bit of count, the two data inputs
NETS=$(grep -oE '^\s*wire _[0-9]+_;' counter_gl.v | grep -oE '_[0-9]+_' | sort -t_ -k2 -n)
NETS="rst_n en $(for b in 0 1 2 3 4 5 6 7; do printf 'count[%d] ' $b; done) $NETS"

echo "net,stuck_at,result" > faults.csv
det=0; tot=0; undet=""
for n in $NETS; do
    for v in 0 1; do
        r=$(sim -DFAULT_NET="$n" -DFAULT_VAL="1'b$v")
        tot=$((tot+1))
        if [ "$r" = FAIL ]; then det=$((det+1)); res=detected
        else res=UNDETECTED; undet="$undet $n/sa$v"; fi
        echo "$n,$v,$res" >> faults.csv
    done
done
echo "fault sites: $(echo $NETS | wc -w) nets x 2 = $tot stuck-at faults (clk excluded)"
echo "detected:    $det"
awk -v d=$det -v t=$tot 'BEGIN{printf "coverage:    %.2f%%\n", 100*d/t}'
[ -n "$undet" ] && echo "undetected: $undet"
exit 0
