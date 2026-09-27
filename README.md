# TensorForge

TensorForge is an MLIR-based compiler for a small tensor dialect (`tforge`: matmul, bias_add, add, relu) that generates single-threaded x86 code and NVIDIA GPU kernels, built on upstream MLIR/LLVM 23. It measures what each transformation (fusion, tiling, vectorization, shared-memory promotion, register tiling) does to the generated code and its speed, and compares an analytical tile-selection cost model with autotuning.

Headline: fused `relu(A @ B + bias)` reaches 41.6 TFLOP/s at 2048^3 on an RTX PRO 6000 Blackwell with the default configuration (44.0 autotuned), against 50.7 for cuBLAS plus a separate epilogue and 41.7 for Triton. On one CPU core it reaches 81 to 100 GFLOP/s, and plain matmul matches or beats single-threaded OpenBLAS at 4 of 5 shapes. The full report is `docs/report.md`; `docs/index.md` lists all documents.

## Architecture

```
 tforge dialect (add, relu, matmul, bias_add)          TensorForge: ODS, verifiers, folds
        |  --convert-tforge-to-linalg                  TensorForge
        v
 linalg on tensors (fill + matmul, generic)            upstream
        |
        +-- --tforge-cpu-pipeline                      TensorForge pipeline, upstream passes inside
        |     tile-and-fuse (reg tile 6x16, K 4)       TensorForge pass over upstream TilingInterface
        |     vectorize (vector.contract)              upstream linalg::vectorize
        |     one-shot-bufferize, out-params           upstream
        |     vector -> outer products -> LLVM         upstream
        |     opt -O3, llc -O3 -mcpu=native -> .so     upstream LLVM
        |     tforge-cpu-bench (C++ harness)           TensorForge
        |
        +-- --tforge-gpu-pipeline
              tforge-gpu-tile (block, thread, K,       TensorForge pass that generates and applies
                shared-memory promotion)                 upstream Transform-dialect scripts
              vectorize, bufferize, map to GPU         upstream (+ TensorForge sequencing)
              tforge-gpu-sink-constants                TensorForge
              gpu-kernel-outlining, convert-gpu-to-nvvm upstream
              tforge-gpu-extract (launch metadata,     TensorForge
                noalias, 16-byte alignment)
              mlir-translate, opt -O3, llc sm_120,     upstream LLVM, CUDA 13.3 ptxas
                ptxas -O3
              tforge-gpu-bench (CUDA driver API,       TensorForge
                cuBLAS baseline, NVML clocks)
```

## Upstream MLIR versus TensorForge

| Component | Source |
|---|---|
| Linalg, Tensor, Arith, SCF, MemRef, Vector, GPU, NVVM dialects | Upstream MLIR |
| One-shot bufferization, TilingInterface tiling and fusion, Transform dialect ops, `linalg::vectorize` | Upstream MLIR |
| LLVM code generation (X86, NVPTX), `ptxas` | Upstream LLVM, CUDA 13.3 |
| `tensorforge-opt` driver | TensorForge (thin wrapper over upstream `MlirOptMain`) |
| `tforge` dialect, verifiers, canonicalizations | TensorForge (Stages 1-2) |
| `tforge` to Linalg lowering | TensorForge (Stage 3) |
| CPU and GPU pipelines and their passes (`tforge-tile-and-fuse`, `tforge-vectorize`, `tforge-gpu-tile`, `tforge-gpu-map`, `tforge-gpu-sink-constants`, `tforge-gpu-extract`, `tforge-print-ir`) | TensorForge (Stages 4-8, E4) |
| CPU and GPU runners, benchmark drivers, cost model, autotuner | TensorForge (Stages 4-9) |

## Build

Requirements: Linux x86-64, micromamba (or conda), CUDA 13.x for the GPU runner. On UC Davis Hive, heavy steps run as Slurm jobs:

```
git clone git@github.com:NirakChoun/TensorForge.git && cd TensorForge
sbatch scripts/setup_env.sh          # MLIR/LLVM 23.1.2, cmake, ninja, lit into ~/tforge-env (environment.yml)
sbatch scripts/build_lit_tools.sh    # FileCheck, not, count (not packaged by conda-forge)
scripts/run_job.sh cpu env JOBS=8 scripts/build.sh   # configure, build, GPU runner if nvcc exists, lit tests
```

`scripts/env.sh` activates the environment and loads `cuda/13.3.0`. `scripts/run_job.sh gpu|cpu <cmd>` runs any command in a Slurm job after printing an environment report. `scripts/devjob.sh` and `scripts/in_job.sh` hold one allocation for interactive work (see `docs/progress.md`, "How to resume").

## Worked example

`examples/mbr.mlir` is `relu(x @ w + b)` with x 256x128 and w 128x256:

```mlir
%mm = tforge.matmul %x, %w : tensor<256x128xf32>, tensor<128x256xf32> -> tensor<256x256xf32>
%ba = tforge.bias_add %mm, %b : tensor<256x256xf32>, tensor<256xf32> -> tensor<256x256xf32>
%r = tforge.relu %ba : tensor<256x256xf32> -> tensor<256x256xf32>
```

Lower it to Linalg, then compile it with the staged GPU pipeline, printing the IR after each stage:

```
build/bin/tensorforge-opt examples/mbr.mlir --convert-tforge-to-linalg
build/bin/tensorforge-opt examples/mbr.mlir \
    --tforge-gpu-pipeline="block-tile=128,64 thread-tile=8,4 tile-k=16 promote=1 vectorize=1 print-after-each=1" \
    -o device.mlir 2> stages.mlir
```

The first command gives `linalg.fill` + `linalg.matmul` and two `linalg.generic` ops. The second gives an NVVM module whose attribute records the launch (`tforge.launch = {kernel = "entry_kernel", grid = [4, 2, 1], block = [16, 16, 1], ...}`); `stages.mlir` holds the IR after `tforge-to-linalg`, `gpu-tiling`, `bufferization`, `gpu-mapping`, and `outlining`.

The Python drivers run the rest of the chain (`mlir-translate`, `opt`, `llc`, `ptxas`), check the result against FP64, and time it:

```
scripts/run_job.sh cpu python3 bench/cpu_bench.py --csv ex.csv --tag example --workloads mbr --shapes 256x256x128 \
    --variant fused-vec="fuse-elementwise=1 reg-tile=6,16,4 vectorize=1" --numpy

[PASS]      fused-vec    mbr    256x256x128 err/bound=0.0237 max_abs=5.98e-06
        median 0.1711 ms  98.08 GFLOP/s  alloc 0 B
        numpy  0.2610 ms  64.27 GFLOP/s
```

(One core of an AMD EPYC 9554, job 24153819.) The kernel matches the FP64 reference within 2.4% of the error bound, allocates no temporaries, and runs 1.5x faster than NumPy's unfused matmul, add, and maximum. `bench/gpu_bench.py` does the same for GPU kernels and cuBLAS.

## Results

| Stage | Question | Result |
|---|---|---|
| 4 | CPU end to end | Scalar baseline 0.6 to 2.8 GFLOP/s; OpenBLAS (1 thread) 44 to 92 |
| 5 | Fusion | Fused kernel allocates no temporaries (two MxN buffers before); time within a few percent |
| 6 | CPU tiling, vectorization | 81 to 100 GFLOP/s (6x16 register tile, `vfmadd231ps`, 2 FMA/cycle per `llvm-mca`) |
| 7 | GPU path | One output per thread: 2.3 to 3.6 TFLOP/s; cuBLAS 13 to 52 |
| 8 | GPU memory hierarchy | 41.6 TFLOP/s at 2048^3; ahead of KernelForge v6 at every shape; 9% ahead of cuBLAS + epilogue at 777x1111x333 |
| 9 | Cost model vs autotuning | Model pick reaches 0.74 to 0.90 of the autotuned best (geometric mean 0.81); vectorization is the largest step in the ablation (2.4x to 2.6x) |
| E1 | Numerics | Only FMA contraction changes bits; tiling, fusion, BK, KR do not; all within 1.5% of the FP64 bound |
| E2 | Cost model on RTX A6000 | Model pick reaches 0.68 to 0.86 of the autotuned best (geometric mean 0.78); same systematic error as on Blackwell |
| E3 | Compile time | 0.18 to 0.29 s per kernel end to end, independent of shape; MLIR passes 6 to 27 ms |
| E4 | Debugging | `print-after-each=1` stage dumps; diagnostics carry `tforge` source locations |

GPU numbers are for the RTX PRO 6000 Blackwell Max-Q (sm_120) unless noted; CPU numbers are single-threaded on an AMD EPYC 7532. Every number comes from a CSV under `results/` with its commit, versions, device, and job ID. Limitations are listed once, in `docs/report.md`.

## Layout

```
include/, lib/           tforge dialect, conversion, transforms, pipelines
tools/tensorforge-opt/   optimizer driver (upstream dialects and passes registered)
runners/                 CPU (dlopen) and GPU (CUDA driver API) benchmark harnesses
python/, bench/          compile/check/time drivers, cost model, stage scripts
test/                    lit + FileCheck tests
results/                 CSVs and generated-code evidence
examples/                worked example input
scripts/                 environment, build, and Slurm helpers
docs/                    stage reports, project report, progress log
```
