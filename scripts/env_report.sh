#!/bin/bash
# Print the provenance every TensorForge result needs. Safe to run without a GPU.
echo "== env report"
echo "date:      $(date -Is)"
echo "host:      $(hostname)"
echo "job:       ${SLURM_JOB_ID:-none}"
echo "commit:    $(git -C "$HOME/TensorForge" rev-parse --short HEAD 2>/dev/null || echo none)"
echo "mlir-opt:  $(mlir-opt --version 2>/dev/null | grep -m1 -i 'version' || echo missing)"
echo "nvcc:      $(nvcc --version 2>/dev/null | tail -1 || echo missing)"
echo "cpu:       $(lscpu 2>/dev/null | grep -m1 'Model name' | sed 's/Model name:[ ]*//')"
echo "cpus:      ${SLURM_CPUS_PER_TASK:-$(nproc)}"
if command -v nvidia-smi >/dev/null 2>&1 && nvidia-smi -L >/dev/null 2>&1; then
  nvidia-smi --query-gpu=name,driver_version,clocks.sm,clocks.max.sm,power.limit --format=csv,noheader
fi
echo "=="
