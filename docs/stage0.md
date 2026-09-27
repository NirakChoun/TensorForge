# Stage 0: toolchain and `tensorforge-opt`

## Question

Can TensorForge build against a prebuilt MLIR/LLVM on Hive, with an optimizer driver and a working lit/FileCheck test setup, without building LLVM from source? Yes: conda-forge MLIR/LLVM 23.1.2 works; only `FileCheck`, `not`, and `count` had to be built.

## Design

Upstream MLIR provides everything in this stage except the glue. TensorForge adds:

- `tools/tensorforge-opt`: a thin wrapper over upstream `MlirOptMain` that registers all upstream dialects, dialect extensions, and passes. Later stages add the `tforge` dialect and TensorForge passes here.
- `test/`: a lit suite (`check-tensorforge`) that uses the environment's `lit` and LLVM's `FileCheck`.
- `scripts/`: `env.sh` (activate env, load CUDA 13.3), `env_report.sh` (provenance header), `run_job.sh` (Slurm wrapper with a `gpu`/`cpu` switch), `build.sh`, `setup_env.sh`, `build_lit_tools.sh`.

## Setup

| Item | Value |
|---|---|
| MLIR / LLVM | 23.1.2, conda-forge (`mlir`, `llvmdev`, `llvm-tools`) |
| `FileCheck`, `not`, `count` | built from the llvm-project 23.1.2 release source |
| Host compiler | conda-forge GCC 15.3.0 (system GCC 11.4 not used) |
| Build | CMake 4.4.3, Ninja 1.13.2, Release |
| CUDA | Hive module `cuda/13.3.0` (`ptxas` present) |
| NVPTX | `llc -march=nvptx64 -mcpu=help` lists `sm_120`, `sm_120a`, `sm_120f` |
| Environment size | 822 MB at `~/tforge-env`; home directory 3.9 GB after Stage 0 |

| Job | Purpose | Result |
|---|---|---|
| 24056755 | create `~/tforge-env`, verify toolchain | completed |
| 24057107 | build lit tools (partial source extract) | failed: LLVM CMake needs `libc/` |
| 24057315 | build lit tools (full source extract) | completed |
| 24091186 | build `tensorforge-opt`, run lit | build ok; lit config error |
| 24091374 | build `tensorforge-opt`, run lit | 2/2 tests passed |

## Results

- `tensorforge-opt` builds (static link, 117 MB binary) and registers 47 upstream dialects, including arith, bufferization, gpu, linalg, memref, nvvm, scf, tensor, transform, and vector.
- `test/round-trip.mlir`: a matmul + bias + ReLU function written with Linalg, Tensor, and Arith round-trips in both custom and generic syntax.
- `test/registration.mlir`: required dialects and passes are registered, and `--canonicalize` folds a constant add.
- A mutated input (`maximumf` replaced with `minimumf`) makes the round-trip FileCheck fail, so the checks are not vacuous.

## Observations

- conda-forge `llvmdev` and `llvm-tools` 23.1.2 do not ship `FileCheck`, `not`, or `count`.
- The installed `LLVMConfig.cmake` does not provide a usable `LLVM_EXTERNAL_LIT`; the project uses the environment's `lit`.
- lit 23 rejects `ShTest(execute_external=True)`; the suite uses lit's internal shell.
- Compute nodes have outbound HTTPS, so conda and GitHub downloads work inside Slurm jobs.

## Interpretation

TODO(Nirak)

## Open questions

- CMake reports `Could NOT find ZLIB (missing: ZLIB_LIBRARY)` during configure. The build and tests are unaffected; revisit if a later stage needs compressed debug sections or offload bundles.
