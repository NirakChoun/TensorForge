#!/bin/bash
# Stage 6 CPU tile sweep for relu(matmul + bias): register tile x cache tile.
# Every variant is correctness-checked before timing (bench/cpu_bench.py).
set -euo pipefail
cd "$(dirname "$0")/.."
CSV=${CSV:-results/cpu/stage6_sweep.csv}
args=(--variant "scalar-fused-32=fuse-elementwise=1 tile-sizes=32,32")
for reg in 4,16,1 6,16,1 8,8,1 6,16,4; do
  r=${reg//,/x}
  args+=(--variant "r${r}-nocache=fuse-elementwise=1 reg-tile=${reg} vectorize=1")
  for c in 32,32 64,64 96,96 128,128; do
    args+=(--variant "r${r}-c${c//,/x}=fuse-elementwise=1 tile-sizes=${c} reg-tile=${reg} vectorize=1")
  done
done
python3 bench/cpu_bench.py --csv "$CSV" --tag stage6 --workloads mbr "${args[@]}"
