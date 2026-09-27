# TensorForge progress log

Current state: Core stages 0-9 complete. Next: Extended stages E4, E1, E3, E2, then final polish.

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
| Staged GPU kernels compiled for padded shapes; runner pads on device inside the timed region | Register tiles, promotion, and vectorization need static tiles; padding cost stays in the measurement |
| Promotion = TensorForge `linalg.copy` into workgroup `alloc_tensor` + upstream `map_copy_to_threads` | Upstream `promote_tensor` materializes copies that cannot be distributed |
| Accumulator hoisting on GPU: fold-memref-alias-ops + CSE, then upstream `hoistRedundantVectorTransfers` | Folding subviews removes the view-like source that blocks hoisting |
| `align-vectors`: 16-byte alignment on `vector<4xf32>` global accesses when BK, BN, TN are multiples of 4 | Legal by construction (cudaMalloc alignment, padded row lengths, 128-bit copy distribution); gives LDG/STG.E.128 |
| Default GPU config for later stages: `block-tile=128,64 thread-tile=8,4 tile-k=16 promote=1 vectorize=1` | Best or near-best at 1024^3 and above in the Stage 8 sweep |
| Python drivers: 10-minute subprocess timeout | A pattern loop hung one compile; a hang now fails the step |
| Stage 9 configuration space: 105 staged configs (BM, BN in {32,64,128}; TM x TN in {4x4, 8x4, 4x8, 8x8}; BK in {8,16,32}; 32-1024 threads) | Covers the Stage 8 space and the register/occupancy limits that `ptxas` accepts without spills |
| Cost model constants (32 shared-memory words/cycle/SM, 600-cycle load latency) are assumptions, fixed before the 8-shape run | Calibrating them on the measured data would make the comparison with autotuning circular |

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

## Stage 8 report

Staged GPU kernels (K loop, shared-memory promotion, per-thread register tiles, 128-bit accesses, accumulator hoisted into registers): fused `mbr` 41.6 TFLOP/s at 2048^3 (cuBLAS + epilogue 50.7, Triton fused 41.7), ahead of KernelForge v6 at every shape and 9% ahead of cuBLAS + epilogue at 777x1111x333. 112 TensorForge + 14 Triton + 14 KernelForge runs correct (`results/gpu/stage8*.csv`, `kernelforge_sgemm.csv`; commit dac1827). Shared memory without vectorization is slower than none (accumulator round-trips through global memory). Fixes on the way: a hung compile (pattern ordering), constant kernel operands, hoisting blocked by subviews. Details in `docs/stage8.md`.

## Stage 9 report

The analytical cost model's pick reaches 0.74 to 0.90 of the autotuned best, clock-adjusted (geometric mean 0.81 over 8 shapes, 105 configurations each, 840 checked runs); its ranking correlates weakly with measurement (Spearman -0.00 to 0.47) and it systematically favors 8x8 thread tiles in one-warp blocks. The autotuned best reaches 44.0 TFLOP/s at 2048^3. Ablation of the default pipeline at 2048^3: 6380 (unfused) -> 6565 (+fusion) -> 12822 (+tiling) -> 16548 (+shared memory) -> 41649 GFLOP/s (+vectorization). Results `results/gpu/stage9_autotune.csv`, `stage9_summary.csv`, `stage9_ablation.csv` (commits 4632965, cd809d9; job 24105050). Details in `docs/stage9.md`; project report in `docs/report.md`.

Before the 8-shape run, one trial at 1000^3 (scratch CSV, not committed) checked the drivers: model pick b32x64-t8x8-k32 0.0975 ms, best b32x64-t4x4-k32 0.0891 ms, ratio 0.914, Spearman 0.423. The model was not changed after it. The naive fused kernel is about 2x faster than in Stage 7 because constant sinking (Stage 8) made the K-loop bound a constant, which lets LLVM unroll it.

## E4 report

Both pipelines take `print-after-each=1`, which prints the module after each named stage (4 CPU, 5 GPU) under a `// ----- tforge: after <stage> -----` header, through a new pass `tforge-print-ir`. With `--mlir-print-debuginfo`, lowered ops carry the `tforge` source location; the staged-kernel error is reported at the `tforge.matmul`'s `file:line:col`. 15/15 lit tests pass (new `test/Pipelines/print-after-each.mlir`; `gpu-staged.mlir` now checks the location). Commit e5e1490. Details in `docs/debugging.md`. Extended-stage commits use the prefixes `e1:` to `e4:` (the brief's `stageN:` format covers only numbered stages).

## E1 report

Only FMA contraction changes results: every TensorForge variant without FMA is bitwise identical to the Stage 4 scalar kernel, and every variant with FMA (CPU vectorized with KR 1 or 4, GPU naive, GPU staged with BK 8, 16, 32) is bitwise identical to the others, at all 8 workload/shape pairs. Contraction changes 40% to 91% of output bits; every variant stays within 1.5% of the FP64-derived bound. OpenBLAS and cuBLAS match TensorForge's FMA results bitwise at some small-K shapes and have 3.2x to 5.5x smaller max error at K = 4096. Results `results/numerics/e1.csv` (job 24105050). Details in `docs/numerics.md`.

The first E1 run was stopped partway to add a bitwise comparison against the FMA variant; `pkill -f` also ended the `srun` step that ran it (its command line contained the pattern). The rerun is the one recorded.

## E3 report

One fused kernel compiles end to end in 0.18 to 0.29 s, independent of problem size; MLIR passes take 6 to 27 ms of that, and process start-up, LLVM, `ptxas`, and linking take the rest. The staged GPU pipeline is the most expensive (27 ms of passes, led by `convert-gpu-to-nvvm` and `tforge-gpu-map`). Results `results/compile/e3.csv` and `timing_*.txt` (job 24105050). Details in `docs/compile_time.md`. This corrected a Stage 9 statement: `docs/stage9.md` had attributed the cost model's 43 to 74 s per shape to compilation without measuring the split; the claim was removed and the question moved to Open questions.

## Open questions

- E3: the Stage 9 cost-model time split (compilation vs one-at-a-time occupancy queries) was not measured.
- E1: TensorForge's large-K error is 3.2x to 5.5x the libraries'; a blocked K reduction was not tried.
- Stage 9: the cost model has no per-warp issue or register-pressure term; whether adding them closes the 0.81 gap was not tested.
- Stage 9: the ablation baseline sums three kernel medians and ignores launch gaps; run-to-run variation between near-tied configurations (0.5% at 4096^3) was not measured.
- CMake `ZLIB_LIBRARY` not found warning during configure (no effect so far).
- Stage 2: the `+0.0` fold only recognizes a direct `relu` producer; a "never -0.0" analysis would cover more cases.
- Stage 8: TensorForge reaches 37 to 38% of clock-adjusted peak at 2048^3 and 4096^3 vs 46 to 48% for Triton and cuBLAS; no software pipelining yet. Padding-copy share of time not measured separately.
- Stage 6: vectorized `add` is 30 to 45% slower than NumPy at 1024x1024; cache tiles that are multiples of 6x16 were not swept.
- Stage 5: fused variants are 7% slower than the baseline at 256^3 only; not explained.
- Stage 4: scalar 512^3 kernels vary by up to 18% with output-buffer placement (446 vs 377 ms at 0 vs 16 byte offset); mechanism not attributed (no hardware counters).
