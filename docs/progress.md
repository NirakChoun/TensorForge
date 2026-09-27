# TensorForge progress log

Current state: Stage 7 complete. Next: Stage 8 (GPU memory hierarchy).

## How to resume

1. `ssh hive hostname` returns `login2`.
2. `cd ~/TensorForge && git log --oneline -30 && git status`.
3. `sacct -u $USER --starttime today` for unprocessed jobs; logs are in `~/TensorForge/logs/` (not committed).
4. Development runs inside one held allocation: `scripts/devjob.sh start cpu 12` (or `gpu 12` for GPU stages; GPU jobs also have 8 CPUs), then `scripts/in_job.sh <cmd>` (add `TF_BG=<name>` to run in the background with output in `logs/<name>.log`). `scripts/devjob.sh stop` when done. Only one Slurm job at a time.
5. Build and test: `scripts/in_job.sh env JOBS=8 scripts/build.sh`, or `scripts/in_job.sh ninja -C build check-tensorforge`.
6. Commit and push: `scripts/commit.sh "stageN: ..."` (refuses to commit build output; no trailers).

Toolchain locations on Hive: micromamba at `~/.local/bin/micromamba` (root prefix `~/.mamba`), environment at `~/tforge-env`. `source scripts/env.sh` activates both it and `cuda/13.3.0`. Recreate the environment with `sbatch scripts/setup_env.sh`, then `sbatch scripts/build_lit_tools.sh`.

## Decisions

| Decision | Reason |
|---|---|
| MLIR/LLVM 23.1.2 from conda-forge, no source build | Newest release on conda-forge; includes `MLIRConfig.cmake` and NVPTX `sm_120` |
| conda-forge GCC 15.3 as host compiler | conda LLVM is built with GCC 15; system GCC 11.4 risks libstdc++ ABI mismatches |
| Build `FileCheck`, `not`, `count` from source in node-local `/tmp` | Not packaged by conda-forge; `/tmp` keeps the LLVM source tree off the 20 GB home quota |
| Static link against MLIR libraries | Default of the conda package; simplest; 117 MB binary |
| lit internal shell | lit 23 deprecates external-shell execution |
| Builds and tests run in CPU Slurm jobs | Linking all of MLIR exceeds login-node etiquette |
| One held allocation (`devjob.sh`) with `srun --overlap` steps | Avoids a queue wait per build while keeping one job at a time |
| `tforge` operands typed `AnyTensor`, checks in C++ verifiers | Lets diagnostics name both shapes involved instead of generic ODS messages |
| CPU backend: `opt -O3` then `llc -O3 -mcpu=native`, kernels as `.so` loaded by `tforge-cpu-bench` | Conventional AOT path; one harness binary for every kernel; assembly available for inspection |
| Kernel ABI: results as out-params (`buffer-results-to-out-params{hoist-static-allocs}`), C interface | Caller owns the output, so allocation counts measure only temporaries |
| Allocation accounting via `finalize-memref-to-llvm{use-generic-functions}` hooks in the harness | Exact bytes requested per call, no allocator interposition |
| No CSE before bufferization in the baseline | CSE of `tensor.empty` makes every op write in place, hiding the unfused baseline; measured separately in Stage 5 |
| Matmul tolerance `gamma_{K+1} (|A||B| + |bias|)` against FP64 | Deterministic bound valid for every summation order, so it also covers tiled and vectorized code |
| All harness buffers 64-byte aligned (commit 30cca26) | 512^3 times depended on output placement by up to 18%; Stage 4 and 5 re-measured, earlier CSVs moved to `results/cpu/superseded/` |
| Commit code before timing runs | Every CSV row then carries a clean commit hash |
| Fusion = upstream elementwise fusion + TensorForge tile-and-fuse + in-place epilogue rewrite + upstream empty-tensor elimination | Zero temporaries; the only non-upstream rewrite is `EpilogueIntoProducerInit` |
| No CSE between tiling and bufferization | CSE merges the fill's and the output's `tensor.empty`, forcing a full temporary and a copy |
| Register tiling = the same `tforge-tile-and-fuse` pass applied again with `peel=1` and `tile-k` | One mechanism for cache and register tiles; peeling gives static full tiles |
| `linalg::vectorize(createNamedContraction=true)` | Default vectorization (multi_reduction) produced no FMAs after contract lowering |
| Accumulator hoisting with upstream `loop-invariant-subset-hoisting` on tensors | Upstream `hoistRedundantVectorTransfers` refuses subview-based accumulators |
| Default CPU config for later stages: `fuse-elementwise=1 reg-tile=6,16,4 vectorize=1` (no cache tile) | Best at 4 of 5 sweep shapes |
| GPU tiling and mapping via Transform scripts generated inside passes (`tforge-gpu-tile`, `tforge-gpu-map`) | Upstream exposes block/thread mapping only as Transform ops; scripts keep the pipeline registered and parameterized |
| GPU kernel ABI: bare pointers, `noalias` | Distinct buffers by construction; lets LLVM keep accumulators in registers |
| GPU backend: `opt -O3 -mcpu=sm_120`, `llc -fp-contract=fast`, `ptxas -O3` | Without `opt`, loads stayed generic and the accumulator was stored every K step; contraction gives FFMA (nvcc default) |
| GPU runner built with nvcc and system GCC 11 | Runner links no MLIR; avoids nvcc/GCC 15 compatibility questions |
| GPU clock-adjusted metric = % of FP32 peak at median NVML SM clock sampled per rep | KernelForge convention; per-rep sampling works for short runs |

## Stage 0 report

Toolchain, `tensorforge-opt`, and lit infrastructure are in place; 2/2 lit tests pass. Details and job table in `docs/stage0.md`.

Failures on the way: the first lit-tools build extracted only part of the LLVM source (fixed by extracting all of it); the first lit run used the deprecated external shell (fixed). The GitHub repository did not exist at session start; Nirak created it during the session.

Commits: see `git log` (`stage0:` prefix).

## Stage 1 report

The `tforge` dialect (add, relu, matmul, bias_add) is defined with verifiers; 4/4 lit tests pass, including 18 rejected cases. Semantics in `docs/dialect.md`, report in `docs/stage1.md`. One test expectation was adjusted for MLIR 23's ODS wording ("any non-token type"). A TableGen doc string containing `}]` ended its code block early; reworded.

## Stage 2 report

Folders for `relu(relu(x))`, `add`/`bias_add` with a zero splat, and constant folding of `add`, `relu`, `bias_add`; 5/5 lit tests pass. Decision: `x + (+0.0) -> x` is not exact because of signed zero, so it is folded only when `x` is a `relu` result; `x + (-0.0) -> x` is always folded. Legality arguments in `docs/stage2.md`.

## Stage 3 report

`--convert-tforge-to-linalg` lowers all four ops (matmul to fill + `linalg.matmul`, elementwise ops to `linalg.generic`); 6/6 lit tests pass, with `--implicit-check-not=tforge.` proving no `tforge` ops remain. Details in `docs/stage3.md`.

## Stage 4 report

`--tforge-cpu-pipeline` compiles all four workloads to native code; 36/36 correctness checks pass (bit-exact elementwise, matmul within the FP64-derived bound). Baseline matmul is scalar, 0.6 to 2.8 GFLOP/s against 44 to 92 GFLOP/s for single-threaded OpenBLAS (`results/cpu/stage4.csv`, commit 30cca26, job 24093215). Failures on the way: `llvm-request-c-wrappers` must be nested under `func.func`; `buffer-results-to-out-params` needs `modify-public-functions`; a dangling lambda capture in the harness crashed matmul runs (fixed before any result was recorded). Details in `docs/stage4.md`.

## Stage 5 report

Fused `relu(matmul + bias)` allocates no temporaries (baseline: two MxN buffers) and writes each output tile once; 20/20 kernels correct. Time changes by at most a few percent at non-power-of-two shapes because the scalar matmul dominates; 512^3 differences follow the Stage 4 placement effect. Results `results/cpu/stage5.csv` (commit 30cca26), IR in `results/cpu/stage5_ir/`. The first fused version kept a full-size temporary because CSE merged `tensor.empty` ops and because a loop-carried result blocked out-param hoisting; both fixed before measuring. Details in `docs/stage5.md`.

## Stage 6 report

Register tiling (6x16, K step 4) with peeling, vectorization to `vector.contract`, and outer-product lowering gives 81 to 100 GFLOP/s single-threaded for fused `relu(matmul + bias)` (scalar: 0.6 to 2.8), at or above OpenBLAS for matmul at 4 of 5 shapes. 141 kernels correct. Cache tiles that are not multiples of the register tile hurt (scalar remainder strips). Assembly shows 12 `ymm` accumulators and `vfmadd231ps`; `llvm-mca` predicts 2 FMAs/cycle for the inner loop. Results `results/cpu/stage6_sweep.csv`, `results/cpu/stage6_best.csv` (commit e6f9f8e), IR/asm in `results/cpu/stage6_ir/`. Details in `docs/stage6.md`.

## Stage 7 report

`--tforge-gpu-pipeline` compiles fused `relu(matmul + bias)` to an sm_120 kernel (Transform-dialect tiling and mapping, NVVM, `ptxas`), run through the CUDA driver API. 70/70 kernels correct (FP64 bound; max difference from cuBLAS 3.6e-4 at 4096^3). One output per thread: 2.3 to 3.6 TFLOP/s (about 3% of FP32 peak at median clock) vs cuBLAS 13 to 52 TFLOP/s (`results/gpu/stage7.csv`, commit 255fa32, job 24105050). Fixes on the way: self-copies from `parallel_insert_slice` (fixed with CSE), f32 constant kernel operands, `opt -O3` and FP contraction for the NVPTX backend. Details in `docs/stage7.md`.

## Open questions

- CMake `ZLIB_LIBRARY` not found warning during configure (no effect so far).
- Stage 2: the `+0.0` fold only recognizes a direct `relu` producer; a "never -0.0" analysis would cover more cases.
- Stage 7: driver-reported register counts (22) differ from `ptxas -v` (18) for some kernels.
- Stage 6: vectorized `add` is 30 to 45% slower than NumPy at 1024x1024; cache tiles that are multiples of 6x16 were not swept.
- Stage 5: fused variants are 7% slower than the baseline at 256^3 only; not explained.
- Stage 4: scalar 512^3 kernels vary by up to 18% with output-buffer placement (446 vs 377 ms at 0 vs 16 byte offset); mechanism not attributed (no hardware counters).
