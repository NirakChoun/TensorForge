#!/bin/bash
# Configure, build, and test TensorForge.
#   scripts/build.sh            # login node: -j 2 (Hive etiquette)
#   JOBS=8 scripts/build.sh     # inside a Slurm job
set -euo pipefail
cd "$(dirname "$0")/.."
source scripts/env.sh
BUILD_DIR="${BUILD_DIR:-build}"
JOBS="${JOBS:-2}"

cmake -G Ninja -S . -B "$BUILD_DIR" \
  -DCMAKE_BUILD_TYPE=Release \
  -DMLIR_DIR="$MLIR_DIR" \
  -DLLVM_DIR="$LLVM_DIR" \
  -DCMAKE_C_COMPILER="$CC" \
  -DCMAKE_CXX_COMPILER="$CXX"
ninja -C "$BUILD_DIR" -j "$JOBS" tensorforge-opt
ninja -C "$BUILD_DIR" -j "$JOBS" check-tensorforge
