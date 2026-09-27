#!/bin/bash
#SBATCH --job-name=tf-env
#SBATCH --account=publicgrp
#SBATCH --partition=high
#SBATCH --cpus-per-task=4
#SBATCH --mem=16G
#SBATCH --time=01:00:00
#SBATCH --output=/home/%u/TensorForge/logs/slurm-%j.out
# Create ~/tforge-env from environment.yml and verify the toolchain.
# Runs as a Slurm job because the install is too large for the login node.
set -euo pipefail
export MAMBA_ROOT_PREFIX="$HOME/.mamba"
MM="$HOME/.local/bin/micromamba"
cd ~/TensorForge
echo "host: $(hostname)  job: ${SLURM_JOB_ID:-none}  date: $(date -Is)"
du -sh ~ 2>/dev/null

if [[ ! -d "$HOME/tforge-env" ]]; then
  "$MM" create -y -p "$HOME/tforge-env" -f environment.yml
fi
# The package cache is only needed during install; it counts against the 20 GB quota.
"$MM" clean -y --all >/dev/null

"$MM" list -p "$HOME/tforge-env" --explicit > logs/tforge-env.explicit.txt
"$MM" env export -p "$HOME/tforge-env" > logs/tforge-env.export.yml

source scripts/env.sh
set +e
echo "== verify"
ls "$MLIR_DIR/MLIRConfig.cmake" "$LLVM_DIR/LLVMConfig.cmake"
mlir-opt --version
mlir-tblgen --version | head -3
FileCheck --version | head -3
command -v not count lit
llc -march=nvptx64 -mcpu=help 2>&1 | grep -o 'sm_1[02][0-9a-z]*' | sort -u | tr '\n' ' '; echo
llc --version | grep -i -A20 'Registered Targets' | grep -i -E 'x86-64|nvptx64'
ptxas --version | tail -1
cmake --version | head -1; ninja --version; "$CXX" --version | head -1
du -sh "$HOME/tforge-env" ~
