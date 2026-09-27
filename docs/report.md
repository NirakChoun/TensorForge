# TensorForge report

## Motivation

TensorForge asks how compiler transformations turn a high-level tensor program into efficient CPU and GPU code, and how to show that the generated code is actually better. It compiles one fused workload, `relu(A @ B + bias)` in FP32, plus its parts (`add`, `relu`, `matmul`, `bias_add`), and measures each transformation against library baselines, with IR, assembly, or SASS showing that the transformation happened. On the GPU, the staged pipeline reaches 41.6 TFLOP/s at 2048^3, above KernelForge's hand-written v6 SGEMM at every measured shape. It reaches 82% of cuBLAS plus a separate epilogue at 2048^3 and is 9% faster than that baseline at 777x1111x333. A simple analytical cost model picks tile configurations that reach 0.74 to 0.90 of the autotuned best.

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

| Component | Source |
|---|---|
| Linalg, Tensor, Arith, SCF, MemRef, Vector, GPU, NVVM dialects; bufferization; TilingInterface; Transform dialect ops; LLVM X86 and NVPTX back ends | Upstream MLIR/LLVM 23.1.2 |
| `tforge` dialect, verifiers, canonicalizations and folds | TensorForge (Stages 1-2) |
| `tforge` to Linalg conversion | TensorForge (Stage 3) |
| CPU and GPU pipelines, the passes named above, tile choices, backend flags | TensorForge (Stages 4-8) |
| CPU and GPU runners, benchmark drivers, provenance CSVs | TensorForge (Stages 4-8) |
| Cost model, autotuner, ablation | TensorForge (Stage 9) |

## Transformations

| Transformation | Where | Evidence |
|---|---|---|
| Fusion of matmul, bias_add, relu into one tiled loop nest; epilogue folded into the matmul init | CPU and GPU | Stage 5 IR: 0 bytes of temporaries vs two MxN buffers |
| CPU register tiling 6x16, K step 4, peeling of remainders | CPU | Stage 6 IR and asm: 12 `ymm` accumulators, `vfmadd231ps` |
| Vectorization to `vector.contract`, lowered to outer products | CPU and GPU | Stage 6 asm; Stage 8 SASS `LDG.E.128` |
| Block and thread tiling, mapping to `gpu.launch` | GPU | Stage 7 IR and PTX |
| Shared-memory promotion of A and B tiles, cooperative copies | GPU | Stage 8 SASS `LDS.128`/`STS.128` |
| Accumulator hoisting into registers | GPU | Stage 8 SASS: 48 scalar `STG.E` without hoisting vs 8 `STG.E.128` with it |
| Constant sinking into kernels | GPU | Stage 9: K-loop bound constant, 64 unrolled `FFMA` vs 1 |

## Methodology

Every result comes from a Slurm job on UC Davis Hive; every CSV row records commit, MLIR/LLVM and CUDA versions, device, job ID, date, workload, shape, pipeline, tile parameters, warm-up and rep counts, median, min, standard deviation, and for the GPU the median SM clock. Timings use at least 10 warm-up and 100 timed runs, and medians are reported. Every kernel is checked before timing against an FP64 reference with the bound gamma_{K+1} (|A||B| + |bias|); elementwise ops must be bit-exact. Shapes include non-multiples of every tile size (777x1111x333, 1000^3, 3000x2000x1000). GPU throughput is also reported as % of FP32 peak at the median SM clock sampled with NVML during the run, because the GPU is power-capped and its clock varies from 1515 to 2332 MHz. Hardware counters are unavailable on Hive, so claims rest on generated IR, assembly, PTX, SASS, `ptxas` resource reports, the occupancy API, and `llvm-mca`.

Hardware: CPU results on an AMD EPYC 7532 (Zen 2) node, single thread, pinned (`lscpu` in `results/cpu/`); GPU results on an NVIDIA RTX PRO 6000 Blackwell Max-Q (sm_120, 188 SMs).

## Results

| Stage | Result | Source |
|---|---|---|
| 4 | Scalar CPU baseline matmul 0.6 to 2.8 GFLOP/s; OpenBLAS (1 thread) 44 to 92 | `results/cpu/stage4.csv` |
| 5 | Fusion removes both MxN temporaries; time within a few percent (scalar matmul dominates) | `results/cpu/stage5.csv` |
| 6 | Tiled and vectorized fused kernel 81 to 100 GFLOP/s single-threaded; at or above OpenBLAS matmul at 4 of 5 shapes | `results/cpu/stage6_best.csv` |
| 7 | Naive GPU kernel (one output per thread) 2.3 to 3.6 TFLOP/s; cuBLAS 13 to 52 | `results/gpu/stage7.csv` |
| 8 | Staged GPU kernel 41.6 TFLOP/s at 2048^3 (cuBLAS + epilogue 50.7, Triton fused 41.7); ahead of KernelForge v6 at every shape; 9% ahead of cuBLAS + epilogue at 777x1111x333 | `results/gpu/stage8.csv`, `stage8_triton.csv`, `kernelforge_sgemm.csv` |
| 9 | Cost-model pick reaches 0.74 to 0.90 of autotuned best (geometric mean 0.81); autotuned best 44.0 TFLOP/s at 2048^3 | `results/gpu/stage9_*.csv` |

Stage 9 ablation, fused `mbr` at 2048^3, GFLOP/s: unfused baseline 6380, +fusion 6565, +tiling 12822, +shared-memory promotion 16548, +vectorization 41649. Full tables are in `docs/stage9.md`.

## Observations

- On both targets, the transformation that changes throughput most is vectorization combined with register tiling. On the GPU it adds 2.4x to 2.6x on top of shared-memory promotion; on the CPU the step from scalar to tiled and vectorized code takes 0.6-2.8 to 81-100 GFLOP/s.
- Fusion's main effect is memory: it removes intermediates, but it changes time little when the matmul is compute-bound.
- Shared-memory promotion without vectorization and accumulator hoisting is slower than no promotion (Stage 8), because the accumulator makes a round trip through global memory every K step.
- The cost model underestimates every configuration's time and most strongly favors 8x8 thread tiles in one-warp blocks; its ranking correlates weakly with measurement (Spearman -0.00 to 0.47).
- Backend flags matter as much as MLIR passes: without `opt -O3`, NVPTX kept generic loads; without FP contraction there was no `FFMA`; without constant sinking the K loop did not unroll.

## Interpretation

TODO(Nirak)

## Limitations

- One workload family (FP32 matmul with a bias and relu epilogue), static shapes only.
- The GPU kernels have no software pipelining (no double buffering or `cp.async`) and no Tensor Cores; they reach 37 to 40% of clock-adjusted FP32 peak at large shapes vs 46 to 48% for cuBLAS and Triton.
- Staged GPU kernels are compiled for padded shapes; the runtime pads on the device, and the padding is included in the timing but not measured separately.
- CPU results are single-threaded.
- No hardware counters: cache, bank-conflict, and stall claims are not measured directly.
- The cost model's two assumed constants (shared-memory words per cycle, global-load latency) were not calibrated.
- The GPU is power-capped; absolute times vary with clock, so the clock-adjusted metric is the one to compare across runs.

## Future work

- Software pipelining of the K loop (double-buffered shared memory, `cp.async`), which the cost model's exposed-latency term suggests is the next large step.
- A per-warp issue term and a register-pressure term in the cost model; using the model to prune the search before autotuning instead of replacing it.
- Multi-threaded CPU code generation, and Tensor Core (TF32/BF16) lowering on the GPU.
