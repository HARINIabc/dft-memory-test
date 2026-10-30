#!/usr/bin/env bash
# run_mutants.sh : checks that the wrapper testbench can tell a broken design
# from a good one. Each mutant is a copy of counter.v or counter_wrapper.v
# with one deliberate bug. The good design must PASS; every mutant must FAIL.
#
#   run from this folder:  ./run_mutants.sh [seed]
set -u
cd "$(dirname "$0")"
SEED=${1:-1}
WORK=$(mktemp -d)
trap 'rm -rf "$WORK"' EXIT

run() {   # $1 counter file, $2 wrapper file -> prints PASS/FAIL
    iverilog -o "$WORK/sim" "$1" wbr_cell.v "$2" counter_wrapper_tb.v 2>/dev/null \
        || { echo "COMPILE-ERROR"; return; }
    vvp -n "$WORK/sim" +seed="$SEED" | grep -o 'WRAPPER TB [A-Z]*' | awk '{print $3}'
}

# name | file to mutate | from | to
MUTANTS=(
  "core: +1 becomes +2|../counter.v|count + 8'd1|count + 8'd2"
  "core: +1 becomes -1|../counter.v|count + 8'd1|count - 8'd1"
  "core: en ignored|../counter.v|else if (en)|else if (1'b1)"
  "core: en inverted|../counter.v|else if (en)|else if (!en)"
  "core: reset value 1|../counter.v|count <= 8'd0|count <= 8'd1"
  "core: reset ignored|../counter.v|if (!rst_n)|if (1'b0)"
  "core: MSB stuck at 0|../counter.v|count <= count + 8'd1|count <= (count + 8'd1) & 8'h7f"
  "core: bit 3 stuck at 1|../counter.v|count <= count + 8'd1|count <= (count + 8'd1) | 8'h08"
  "wrapper: input cells never in test mode|counter_wrapper.v|.mode(intest)|.mode(1'b0)"
  "wrapper: output cells never drive pins|counter_wrapper.v|.mode(extest)|.mode(1'b0)"
  "wrapper: rst_n/en swapped into core|counter_wrapper.v|.rst_n(core_in[0])|.rst_n(core_in[1])"
  "wrapper: WBY skipped|counter_wrapper.v|:             wby;|:             wsi;"
  "wrapper: capture disabled|counter_wrapper.v|wbr_sel && capturewr|1'b0"
)

printf '%-45s %s\n' "design" "result"
good=$(run ../counter.v counter_wrapper.v)
printf '%-45s %s\n' "original (must PASS)" "$good"
bad=0; [ "$good" = PASS ] || bad=1
caught=0; total=0
for m in "${MUTANTS[@]}"; do
    IFS='|' read -r name file from to <<< "$m"
    cp ../counter.v "$WORK/counter.v"; cp counter_wrapper.v "$WORK/counter_wrapper.v"
    target="$WORK/$(basename "$file")"
    grep -qF "$from" "$target" || { printf '%-45s %s\n' "$name" "PATTERN-NOT-FOUND"; bad=1; continue; }
    python3 -c "import sys;p,a,b=sys.argv[1:];s=open(p).read();open(p,'w').write(s.replace(a,b,1))" \
        "$target" "$from" "$to"
    r=$(run "$WORK/counter.v" "$WORK/counter_wrapper.v")
    total=$((total+1)); [ "$r" = FAIL ] && caught=$((caught+1)) || bad=1
    printf '%-45s %s\n' "$name" "$r"
done
echo "mutants caught: $caught / $total (seed $SEED)"
exit $bad
