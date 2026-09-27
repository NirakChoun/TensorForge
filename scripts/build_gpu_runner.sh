#!/bin/bash
# Build the CUDA driver-API runner with nvcc from the cuda/13.3.0 module.
# The system GCC 11 is the host compiler: nvcc 13.3 does not need conda's GCC 15,
# and the runner links no MLIR code.
set -euo pipefail
cd "$(dirname "$0")/.."
source scripts/env.sh
: "${CUDA_HOME:=$(dirname "$(dirname "$(command -v nvcc)")")}"
mkdir -p build/bin
nvcc -O2 -std=c++17 -ccbin /usr/bin/g++ -arch=sm_120 \
  -o build/bin/tforge-gpu-bench runners/gpu/tforge-gpu-bench.cu \
  -lcuda -lcublas -L"$CUDA_HOME/lib64/stubs" -lnvidia-ml
echo "built build/bin/tforge-gpu-bench"
