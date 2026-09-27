#!/bin/bash
# Re-run KernelForge's SGEMM v5 and v6 binaries (read-only use of
# ~/KernelForge/build/sgemm) at the Stage 8 shapes in this job, so they are
# measured on the same node and session as the TensorForge kernels. KernelForge
# writes its own CSV schema; the SM clock is sampled by nvidia-smi every 50 ms
# and summarized per run into a sidecar CSV.
set -euo pipefail
cd "$(dirname "$0")/.."
out=results/gpu/kernelforge_sgemm.csv
clk=results/gpu/kernelforge_sgemm_clocks.csv
mkdir -p results/gpu
echo "run,median_sm_mhz,samples" > "$clk"
KF=~/KernelForge/build/sgemm
for shape in 256x256x256 512x512x512 1024x1024x1024 2048x2048x2048 4096x4096x4096 1000x1000x1000 777x1111x333; do
  IFS=x read -r M N K <<< "$shape"
  for v in 5 6; do
    log=$(mktemp)
    nvidia-smi --query-gpu=clocks.sm --format=csv,noheader,nounits -lms 50 > "$log" &
    smi=$!
    "$KF" "$M" --ncols "$N" --k "$K" --version "$v" --warmup 10 --reps 100 --csv "$out" | grep -E "RESULT|correctness"
    kill $smi 2>/dev/null || true
    wait $smi 2>/dev/null || true
    med=$(sort -n "$log" | awk '{a[NR]=$1} END {print (NR ? a[int((NR+1)/2)] : -1)}')
    echo "v${v}_${shape},$med,$(wc -l < "$log")" >> "$clk"
    rm -f "$log"
  done
done
