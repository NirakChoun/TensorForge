# Stage 9: cost model versus autotuning

## Question

Can a simple analytical cost model choose tile configurations for fused `relu(A @ B + bias)` on the RTX PRO 6000 Blackwell as well as empirical autotuning? Not with this model. Over 8 shapes, its pick reaches 0.74 to 0.90 of the autotuned best (geometric mean 0.81, clock-adjusted), and its predicted ranking correlates weakly with the measured one (Spearman -0.00 to 0.47). Its errors are systematic: it favors 8x8 thread tiles in 1-warp blocks, which it treats as able to use a whole SM's FMA throughput.

The ablation of the default pipeline shows where the performance comes from: vectorization contributes the largest single step (2.4x to 2.5x at 1024^3 to 4096^3), then shared-memory promotion and tiling; fusion alone changes little on the GPU.

## Design

**Configuration space** (`python/costmodel.py:config_space`): BM, BN in {32, 64, 128}; (TM, TN) in {(4,4), (8,4), (4,8), (8,8)}; BK in {8, 16, 32}; 32 to 1024 threads per block. That gives 105 configurations, all of the Stage 8 staged kernel with promotion and vectorization.

**Cost model** (TensorForge, `python/costmodel.py`). Inputs: tile sizes, the padded problem, registers and shared memory from `ptxas`, and blocks per SM from the CUDA occupancy API (`tforge-gpu-bench --info-only`, no execution). Per configuration:

```
blocks       = (Mp/BM)(Np/BN)
waves        = ceil(blocks / (188 * blocks_per_sm))                 wave quantization over 188 SMs
resident     = min(blocks_per_sm, ceil(blocks / 188))
fma_step     = BM*BN*BK / 128                                       cycles, per block per K step
lds_step     = threads*BK*(TM+TN) / 32                              shared-memory words at 32 per cycle
step         = resident*max(fma_step, lds_step) + max(0, 600 - (resident-1)*max(fma_step, lds_step))
time         = max(waves * (Kp/BK) * step / clock, (Mp*Kp + Kp*Np + Mp*Np)*4 / 1530 GB/s)
```

The last term of `step` is the exposed global-load latency of a K step, since the kernel has no software pipelining; other resident blocks hide it. Arithmetic intensity per block, 2·BM·BN / (4·(BM+BN)) FLOP per byte, enters only through the DRAM floor, because operand re-reads are L2 hits (128 MiB L2).

Hardware facts (188 SMs, 128 FP32 lanes per SM, 1530 GB/s achievable DRAM bandwidth) come from KernelForge. Two constants are assumptions: 32 shared-memory words per cycle per SM, and 600 cycles of global-load latency. They were fixed before any Stage 9 measurement except a one-shape trial at 1000^3 (in `docs/progress.md`) and were not changed afterwards.

**Autotuner** (`bench/stage9_costmodel.py`): every configuration is compiled (8 in parallel), checked against the FP64 bound, and timed with 10 warm-up and 100 timed launches; the fastest median wins.

**Ablation** (`bench/stage9_ablation.py`), `mbr` on the default pipeline:

| Step | Configuration |
|---|---|
| baseline | unfused: three naive kernels (matmul, bias_add, relu), one output per thread, 16x16 blocks; time = sum of the three medians |
| +fusion | one naive fused kernel |
| +tiling | 128x64 blocks, 8x4 per thread, K step 16, no shared memory, not vectorized |
| +shared-memory promotion | + A/B tiles in shared memory |
| +vectorization | + vectorized thread tiles and copies, 128-bit accesses (the default) |

## Setup

GPU and timing method as in Stages 7 and 8 (job 24105050). Cost model and autotuner: commit 4632965. Ablation: commit cd809d9. Shapes: 1024^3, 2048^3, 4096^3, 1536^3, 2560^3, 1000^3, 777x1111x333, 3000x2000x1000. Files: `results/gpu/stage9_autotune.csv` (840 rows: every configuration, with the model's prediction and terms in `notes`), `stage9_summary.csv`, `stage9_ablation.csv`.

## Results

All 105 configurations compiled at every shape; all 840 autotuner runs and all ablation kernels passed correctness.

| Shape | Model pick | % of peak | Autotuned best | % of peak | Pick / best (clock-adj.) | Spearman | Model's rank of best |
|---|---|---|---|---|---|---|---|
| 1024^3 | 32x64, 8x8, 32 | 26.2 | 32x64, 4x4, 32 | 31.2 | 0.839 | 0.465 | 33 |
| 2048^3 | 32x64, 8x8, 8 | 31.9 | 64x128, 8x4, 32 | 40.1 | 0.796 | 0.201 | 53 |
| 4096^3 | 32x64, 8x8, 8 | 29.3 | 128x64, 8x4, 32 | 37.8 | 0.777 | 0.262 | 49 |
| 1536^3 | 32x64, 8x8, 8 | 28.0 | 128x128, 8x4, 32 | 38.0 | 0.738 | -0.001 | 73 |
| 2560^3 | 64x64, 8x8, 32 | 35.0 | 64x64, 8x4, 32 | 40.3 | 0.868 | 0.306 | 29 |
| 1000^3 | 32x64, 8x8, 32 | 18.5 | 32x64, 4x4, 32 | 20.6 | 0.899 | 0.418 | 40 |
| 777x1111x333 | 32x64, 8x8, 32 | 10.4 | 32x32, 4x4, 16 | 13.1 | 0.798 | 0.284 | 23 |
| 3000x2000x1000 | 32x64, 8x8, 8 | 26.3 | 64x128, 8x4, 32 | 33.9 | 0.775 | 0.410 | 21 |

Configurations are BM x BN, TM x TN, BK. "% of peak" is % of FP32 peak at each run's median SM clock. Raw time ratios are the same to within 0.02 except at 4096^3 (0.755) and 2560^3 (0.888).

The autotuned best at 2048^3 is 44.0 TFLOP/s (0.3905 ms), above the fixed Stage 8 configuration (41.6).

Cost of choosing: the model needs compilation plus an occupancy query per configuration, 43 to 74 s per shape (almost all compilation). The autotuner needs compilation plus 105 checked and timed runs, 80 to 182 s per shape.

Where the model is wrong, over all 840 runs (`python/stage9_analysis.py`, post hoc; the model was not changed):

| Group | Configurations | Mean measured % of peak | Mean predicted / measured time |
|---|---|---|---|
| thread tile 4x4 | 216 | 24.1 | 0.69 |
| thread tile 8x4 | 216 | 26.3 | 0.59 |
| thread tile 4x8 | 216 | 21.0 | 0.46 |
| thread tile 8x8 | 192 | 24.5 | 0.38 |

The model underestimates every configuration's time, and 8x8 thread tiles the most. Its top five picks at most shapes are 8x8 tiles in 32x64 or 64x32 blocks, which have only 32 threads (one warp) per block.

Ablation, `mbr`, GFLOP/s (% of FP32 peak at median clock):

| Step | 1024^3 | 2048^3 | 4096^3 | 777x1111x333 |
|---|---|---|---|---|
| baseline (unfused, 3 kernels) | 6336 (5.8%) | 6380 (5.8%) | 6111 (5.6%) | 5414 (4.9%) |
| +fusion | 6564 (6.0%) | 6565 (6.0%) | 6142 (6.1%) | 6037 (5.5%) |
| +tiling | 7619 (6.9%) | 12822 (11.5%) | 10868 (9.7%) | 5841 (5.3%) |
| +shared-memory promotion | 12116 (11.0%) | 16548 (14.8%) | 15436 (14.1%) | 6758 (6.2%) |
| +vectorization (default) | 28606 (26.2%) | 41649 (37.2%) | 40606 (37.1%) | 13066 (11.9%) |

## Observations

- The model's pick is never the autotuned best, and the autotuned best is ranked 21st to 73rd of 105 by the model.
- The model treats a block's FMA work as spread over all 128 lanes of an SM. A 32-thread block issues from one warp, that is, one of the SM's four schedulers; the model has no per-warp issue term. It also has no register-pressure term beyond what occupancy captures, and 8x8 tiles use 128 registers.
- The measured best is an 8x4 thread tile at every shape of 1536^3 and above (2048^3, 4096^3, 1536^3, 2560^3, 3000x2000x1000) and a 4x4 tile at 1000^3, 1024^3, and 777x1111x333. BK = 32 is in every best configuration but one (777x1111x333: 16).
- In the ablation, fusion alone gains 1% to 11%. The unfused baseline's extra cost is two short elementwise kernels next to a slow naive matmul.
- Tiling without shared memory and without vectorization gains 1.2x to 2.0x at 1024^3 to 4096^3 and loses 3% at 777x1111x333. Promotion adds 1.3x to 1.6x, and vectorization adds 2.4x to 2.6x at every shape.
- The naive fused kernel here (6564 GFLOP/s at 1024^3) is about twice as fast as the same configuration in Stage 7 (3321). The Stage 8 constant sinking moved the K-loop bound into the kernel as a constant: the Stage 7 kernel takes K as an argument and its SASS has one `FFMA` in a rolled loop, while the current one has 64 unrolled `FFMA` (38 registers).

## Interpretation

TODO(Nirak)

## Open questions

- The ablation baseline sums three separate kernel medians. It excludes launch gaps and the extra DRAM traffic that would overlap differently in a real sequence.
- 64x128 and 128x64 blocks at 4096^3 differ by 0.5% in the autotuner; run-to-run variation at that level was not measured, so the choice between them is not significant.
