#!/bin/bash
#SBATCH --job-name=tf-filecheck
#SBATCH --account=publicgrp
#SBATCH --partition=high
#SBATCH --cpus-per-task=8
#SBATCH --mem=32G
#SBATCH --time=01:00:00
#SBATCH --output=/home/%u/TensorForge/logs/slurm-%j.out
# Build FileCheck, not, and count from the LLVM release that matches ~/tforge-env,
# because conda-forge's llvmdev/llvm-tools do not ship them. The source tree and
# build live in node-local /tmp so they never touch the home quota; only the three
# binaries are copied into the environment.
set -euo pipefail
cd ~/TensorForge
source scripts/env.sh
VER="$(llvm-config --version)"
echo "host: $(hostname)  job: ${SLURM_JOB_ID:-none}  LLVM ${VER}"

WORK="$(mktemp -d /tmp/tf-llvm-XXXXXX)"
trap 'rm -rf "$WORK"' EXIT
cd "$WORK"
curl -fsSL -o llvm.tar.xz \
  "https://github.com/llvm/llvm-project/releases/download/llvmorg-${VER}/llvm-project-${VER}.src.tar.xz"
# LLVM's CMake reaches into several sibling directories (cmake/, libc/, third-party/),
# so extract the whole tree; it is node-local and removed on exit.
tar -xJf llvm.tar.xz

cmake -G Ninja -S "llvm-project-${VER}.src/llvm" -B build \
  -DCMAKE_BUILD_TYPE=Release \
  -DCMAKE_C_COMPILER="$CC" -DCMAKE_CXX_COMPILER="$CXX" \
  -DLLVM_TARGETS_TO_BUILD=X86 \
  -DLLVM_INCLUDE_TESTS=OFF -DLLVM_INCLUDE_BENCHMARKS=OFF -DLLVM_INCLUDE_EXAMPLES=OFF \
  -DLLVM_ENABLE_ZSTD=OFF -DLLVM_ENABLE_ZLIB=OFF -DLLVM_ENABLE_LIBXML2=OFF -DLLVM_ENABLE_TERMINFO=OFF
ninja -C build -j "${SLURM_CPUS_PER_TASK:-8}" FileCheck not count

for t in FileCheck not count; do
  install -m 0755 "build/bin/$t" "$TF_ENV/bin/$t"
done
FileCheck --version | head -3
echo "not:   $(command -v not)"
echo "count: $(command -v count)"
printf 'a\nb\n' | count 2 && echo "count ok"
not false && echo "not ok"
