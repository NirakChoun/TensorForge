#!/bin/bash
# Extract the first innermost loop that contains the given instruction (default
# vfmadd231ps) from an assembly file and run llvm-mca on it (static throughput
# model; Hive denies hardware counters).
#   bench/mca_inner_loop.sh <asm.s> [mcpu] [instruction]
set -euo pipefail
asm="$1"; mcpu="${2:-znver2}"; insn="${3:-vfmadd231ps}"
tmp=$(mktemp /tmp/mca_loop_XXXX.s)
python3 - "$asm" "$insn" > "$tmp" <<'EOF'
import re, sys
lines = open(sys.argv[1]).read().splitlines()
insn = sys.argv[2]
i = 0
while i < len(lines):
    m = re.match(r"^(\.LBB\w+):", lines[i])
    if m and any("Inner Loop Header" in l for l in lines[i:i + 4]):
        label, body = m.group(1), []
        for l in lines[i + 1:]:
            if re.match(r"^\.LBB\w+:", l):
                break
            body.append(l)
            if re.search(r"\bj\w+\s+" + re.escape(label) + r"\b", l):
                break
        if any(insn in l for l in body):
            print("\n".join(l for l in body if l.strip() and not l.strip().startswith("#")))
            sys.exit(0)
    i += 1
sys.exit("no innermost loop with " + insn)
EOF
echo "== innermost loop with $insn ($(grep -c . "$tmp") instructions) from $asm"
cat "$tmp"
echo "== llvm-mca -mcpu=$mcpu -iterations=1000"
llvm-mca -mcpu="$mcpu" -iterations=1000 "$tmp" 2>&1 | sed -n '1,16p'
rm -f "$tmp"
