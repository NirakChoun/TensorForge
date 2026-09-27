# Source this file (do not execute it): activates the TensorForge toolchain.
#   source scripts/env.sh
# Requires a login shell, because `module` is only defined there.

export MAMBA_ROOT_PREFIX="$HOME/.mamba"
export TF_ENV="$HOME/tforge-env"

# micromamba's shell hook is used instead of plain PATH edits so that the
# environment's activation scripts (compiler wrappers, CC/CXX) also run.
eval "$("$HOME/.local/bin/micromamba" shell hook -s bash)"
micromamba activate "$TF_ENV"

# CUDA 13.3 supplies ptxas, the driver API headers, and cuBLAS; MLIR/LLVM come from the env.
if command -v module >/dev/null 2>&1; then
  module load cuda/13.3.0 >/dev/null 2>&1 || echo "env.sh: warning: could not load cuda/13.3.0" >&2
fi

export MLIR_DIR="$TF_ENV/lib/cmake/mlir"
export LLVM_DIR="$TF_ENV/lib/cmake/llvm"
