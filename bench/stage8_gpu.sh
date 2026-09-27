#!/bin/bash
# Stage 8: staged GPU kernels (K loop, shared-memory promotion, register tiles,
# 128-bit accesses) against cuBLAS (+ separate epilogue kernel for mbr).
set -euo pipefail
cd "$(dirname "$0")/.."
CSV=${CSV:-results/gpu/stage8.csv}
python3 bench/gpu_bench.py --csv "$CSV" --tag stage8 --cublas \
  --variant "noprom-64x64-t4x4-k16=block-tile=64,64 thread-tile=4,4 tile-k=16 vectorize=1" \
  --variant "prom-novec-64x64-t4x4-k16=block-tile=64,64 thread-tile=4,4 tile-k=16 promote=1" \
  --variant "full-64x64-t4x4-k16=block-tile=64,64 thread-tile=4,4 tile-k=16 promote=1 vectorize=1" \
  --variant "full-64x64-t4x4-k32=block-tile=64,64 thread-tile=4,4 tile-k=32 promote=1 vectorize=1" \
  --variant "full-128x64-t8x4-k16=block-tile=128,64 thread-tile=8,4 tile-k=16 promote=1 vectorize=1" \
  --variant "full-128x128-t8x8-k8=block-tile=128,128 thread-tile=8,8 tile-k=8 promote=1 vectorize=1" \
  --variant "full-128x128-t8x8-k16=block-tile=128,128 thread-tile=8,8 tile-k=16 promote=1 vectorize=1"
