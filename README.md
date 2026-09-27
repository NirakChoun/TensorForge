# TensorForge

TensorForge is an MLIR-based tensor compiler that lowers a small tensor dialect (`tforge`) to CPU and NVIDIA GPU code and measures whether each transformation actually makes the generated code faster. It is built on upstream MLIR/LLVM and adds its own dialect, lowerings, pass pipelines, runners, and evaluation.

Status: Stage 2 (canonicalization). See `docs/progress.md` for the current state.

## Upstream MLIR versus TensorForge

| Component | Source |
|---|---|
| Linalg, Tensor, Arith, SCF, MemRef, Vector, GPU, NVVM dialects | Upstream MLIR |
| One-shot bufferization, Linalg tiling and fusion, Transform dialect | Upstream MLIR |
| LLVM code generation (X86, NVPTX) | Upstream LLVM |
| `tensorforge-opt` driver | TensorForge (thin wrapper over upstream `MlirOptMain`) |
| `tforge` dialect, verifiers, canonicalizations | TensorForge (Stage 1-2) |
| `tforge` to Linalg lowering | TensorForge (Stage 3) |
| CPU and GPU pipelines, runners, benchmarks, cost model | TensorForge (Stage 4-9) |

## Toolchain

MLIR/LLVM 23.1.2 from conda-forge, installed with micromamba into `~/tforge-env` (see `environment.yml`). `FileCheck`, `not`, and `count` are not packaged by conda-forge; `scripts/build_lit_tools.sh` builds them from the matching LLVM release. CUDA 13.3 (Hive module `cuda/13.3.0`) provides `ptxas`, the driver API, and cuBLAS.

## Build

On UC Davis Hive:

```
# one-time: micromamba in ~/.local/bin, then (as Slurm jobs)
sbatch scripts/setup_env.sh        # creates ~/tforge-env
sbatch scripts/build_lit_tools.sh  # adds FileCheck, not, count

# build and run the lit tests inside a CPU job
scripts/run_job.sh cpu env JOBS=8 scripts/build.sh
```

`scripts/env.sh` activates the environment and loads CUDA. `scripts/run_job.sh gpu|cpu <cmd>` submits any command to Slurm and prints an environment report first.

## Layout

```
tools/tensorforge-opt/   optimizer driver (upstream dialects and passes registered)
test/                    lit + FileCheck tests
scripts/                 environment, build, and Slurm helpers
docs/                    stage reports and the running progress log
```
