# Stage 8: GPU memory hierarchy

## Question

How close does the MLIR-generated fused `relu(matmul + bias)` kernel get to hand-written and vendor kernels once it stages operand tiles in shared memory, keeps a register tile per thread, and uses 128-bit memory accesses? With one fixed configuration (128x64 block, 8x4 per thread, K step 16) it reaches 41.6 TFLOP/s at 2048^3 and 40.7 at 4096^3, against 50.7 and 50.0 for cuBLAS plus a separate epilogue kernel and 41.7 and 46.1 for Triton's fused kernel. It beats KernelForge's hand-written v6 SGEMM at every tested shape, and at 777x1111x333 it is 9% faster than cuBLAS with its own padding copies included.

## Design

`--tforge-gpu-pipeline="block-tile=BM,BN thread-tile=TM,TN tile-k=BK promote=1 vectorize=1"`. The Stage 7 passes are extended; the structure of one block is:

```
forall threads: fill (TM x TN)                                   accumulator tile
for k step BK:
  forall threads (linear): copy A[BM x BK] -> shared              128-bit per thread
  forall threads (linear): copy B[BK x BN] -> shared
  forall threads: matmul (TM x TN x BK) from shared               vector.contract
forall threads: epilogue (TM x TN)                                bias + relu in registers
```

| Step | Owner | Effect |
|---|---|---|
| block tiling + fusion, then `tile_using_for [0, 0, BK]` on the in-block matmul | upstream Transform ops in the `tforge-gpu-tile` script | K loop per block |
| promotion | TensorForge (`tforge-gpu-tile`) | A and B tiles copied with `linalg.copy` into `bufferization.alloc_tensor {memory_space = #gpu.address_space<workgroup>}` |
| `structured.gpu.map_copy_to_threads ... desired_bit_alignment = 128` | upstream | copies distributed over all threads, 4 floats each |
| `tile_using_forall num_threads [BM/TM, BN/TN]` for fill, matmul, epilogue | upstream | per-thread static register tiles |
| `tforge-vectorize` | TensorForge policy, upstream `linalg::vectorize` | thread tiles to `vector.contract`, copies to vector transfers |
| bufferization, `buffer-loop-hoisting` | upstream | shared tiles allocated once per block |
| `tforge-gpu-map` | TensorForge + upstream | maps foralls to the launch; shared allocations become launch workgroup attributions; `fold-memref-alias-ops` patterns and CSE, then upstream `hoistRedundantVectorTransfers` keeps the TM x TN accumulator in registers across the K loop; per-thread `memref.copy` is vectorized (`linalg::vectorizeCopy`); vector lowering (`transfer_to_scf`, contraction to outer products, rank-1 transfers) |
| `tforge-gpu-sink-constants` | TensorForge | constants cloned into the launch before outlining |
| `tforge-gpu-extract{align-vectors}` | TensorForge | `vector<4xf32>` global loads/stores marked 16-byte aligned; shared arrays 16-byte aligned |

**Static tiles and padding.** Register tiles, promotion, and vectorization need static tile shapes, so the staged kernel is compiled for M, N, K rounded up to BM, BN, BK. The compiler rejects unpadded shapes (`test/Pipelines/gpu-staged.mlir`). For other shapes the runner keeps zeroed padded buffers and, in every timed call, copies A, B, and bias in and the valid block of C out (`cudaMemcpy2DAsync`). The pad regions contribute exact zeros to every dot product, so results are unchanged. The padding cost is part of the measured time.

**Alignment legality** for the 128-bit global accesses: buffers are `cudaMalloc`-aligned (at least 256 bytes); padded row lengths are multiples of BN or BK, which are multiples of 4; copies are distributed at 128-bit granularity; and each thread's C tile starts at a multiple of TN = 4 or 8. The pipeline sets `align-vectors` only when BK, BN, and TN are multiples of 4.

**Problems solved on the way:**

- The first generated compile hung: `transfer_to_scf` and the other lowering patterns in one greedy pattern set kept rewriting each other. They now run as separate steps, and the drivers have a 10-minute subprocess timeout.
- Constant vectors became kernel operands, because canonicalization hoists constants out of `gpu.launch`. The sinking now happens immediately before outlining.
- Accumulator hoisting failed until subviews were folded into the transfers and their index computations were CSE'd.

## Setup

GPU, driver, node, job, timing, and clock method as in Stage 7 (job 24105050, commit dac1827). Shapes: 256^3 to 4096^3, 1000^3, and 777x1111x333 (padded to the block and K tiles for each configuration).

Baselines, all measured in the same job:

- cuBLAS `cublasSgemm` (FP32, default math), plus a separate bias+relu kernel for `mbr`.
- Triton 3.8.0 (KernelForge's venv, used read-only). TensorForge's own fused kernel, `bench/triton_baseline.py`, autotuned over KernelForge's `MATMUL_SPACE`, `input_precision="ieee"`.
- KernelForge v5 (register-blocked) and v6 (vectorized) SGEMM: `~/KernelForge/build/sgemm` re-run at the same shapes (`bench/kernelforge_ref.sh`), plain matmul only.

## Results

All 112 TensorForge kernels, 14 Triton runs, and 14 KernelForge runs pass their correctness checks. Files: `results/gpu/stage8.csv`, `stage8_triton.csv`, `kernelforge_sgemm.csv` (+ `_clocks.csv`).

Ablation-style variants and tile configurations, `mbr`, GFLOP/s (% of FP32 peak at the median SM clock):

| Variant (BM x BN, TM x TN, BK) | 1024^3 | 2048^3 | 4096^3 | 1000^3 | 777x1111x333 |
|---|---|---|---|---|---|
| K loop + register tile, no shared memory, vectorized (64x64, 4x4, 16) | 13355 (12.2%) | 22195 (20.2%) | 24393 (22.2%) | 11079 (9.9%) | 7906 (7.2%) |
| + shared memory, not vectorized (64x64, 4x4, 16) | 11341 (10.3%) | 12522 (11.5%) | 12623 (11.5%) | 9664 (8.8%) | 6630 (6.0%) |
| + shared memory, vectorized (64x64, 4x4, 16) | 27840 (25.4%) | 37017 (33.0%) | 35657 (33.3%) | 20292 (18.5%) | 13076 (11.9%) |
| same, BK = 32 | 28796 (26.2%) | 37673 (34.3%) | 36380 (33.2%) | 20515 (18.8%) | 13033 (11.9%) |
| 128x64, 8x4, 16 | 28691 (26.2%) | 41595 (37.9%) | 40691 (37.1%) | 20945 (19.1%) | 13029 (11.9%) |
| 128x128, 8x8, 8 | 13548 (12.4%) | 31553 (28.9%) | 36620 (33.5%) | 11459 (10.4%) | 7292 (6.6%) |
| 128x128, 8x8, 16 | 15856 (14.5%) | 35038 (31.9%) | 41007 (37.4%) | 12840 (11.7%) | 7916 (7.2%) |

Comparison, plain `matmul`, GFLOP/s (TensorForge: fixed configuration 128x64, 8x4, BK 16):

| Kernel | 256^3 | 512^3 | 1024^3 | 2048^3 | 4096^3 | 1000^3 | 777x1111x333 |
|---|---|---|---|---|---|---|---|
| TensorForge 128x64/8x4/16 | 1551 | 7061 | 28728 | 41562 | 40508 | 21411 | 13626 |
| TensorForge best of 7 configs | 2456 | 11230 | 29389 | 41562 | 41115 | 21411 | 14356 |
| KernelForge v5 | 320 | 1367 | 5675 | 18803 | 23355 | 5430 | 4254 |
| KernelForge v6 | 736 | 3135 | 13133 | 33961 | 37301 | 12550 | 8287 |
| Triton (autotuned) | 1014 | 7014 | 26271 | 42032 | 46214 | 20668 | 10452 |
| cuBLAS | 3048 | 14028 | 37366 | 52436 | 50867 | 34809 | 13338 |

Comparison, fused `mbr`, GFLOP/s (% of FP32 peak at median clock):

| Kernel | 1024^3 | 2048^3 | 4096^3 | 1000^3 | 777x1111x333 |
|---|---|---|---|---|---|
| TensorForge 128x64/8x4/16 | 28691 (26.2%) | 41595 (37.9%) | 40691 (37.1%) | 20945 (19.1%) | 13029 (11.9%) |
| Triton fused (autotuned) | 26057 (24.0%) | 41702 (48.1%) | 46069 (45.9%) | 19586 (18.0%) | 10774 (9.7%) |
| cuBLAS + epilogue kernel | 35470 (32.3%) | 50739 (46.4%) | 49953 (45.7%) | 32183 (29.3%) | 11938 (10.9%) |

Median SM clocks: TensorForge and cuBLAS runs 2227 to 2332 MHz; Triton's 2048^3 and 4096^3 runs 1710 to 1837 MHz, which is why its clock-adjusted values are higher than its raw throughput suggests. KernelForge clocks (`kernelforge_sgemm_clocks.csv`) are the median over each whole process, including its setup and cuBLAS check, so they are not comparable to the per-rep samples and are not used for clock adjustment.

### Generated-code evidence

`results/gpu/stage8_ir/full-128x64-t8x4-k16_mbr_2048/` holds both transform scripts, the tensor IR before bufferization, the device module, PTX, `ptxas -v`, and SASS. `ptxas`: 88 registers, 12288 bytes shared memory, no spills. SASS instruction counts (static):

| Variant (mbr 2048^3) | FFMA | global loads | shared loads | shared stores | global stores | regs |
|---|---|---|---|---|---|---|
| no shared memory, vectorized | 256 | 17 `LDG.E.128.CONSTANT` + 64 `LDG.E.CONSTANT` | 0 | 0 | 4 `STG.E.128` | 40 |
| shared memory, not vectorized | 256 | 32 `LDG.E` + 12 `LDG.E.CONSTANT` | 32 `LDS.128` | 2 `STS.128` | 48 `STG.E` | 64 |
| shared memory, vectorized (64x64, 4x4) | 256 | 3 `LDG.E.128.CONSTANT` | 32 `LDS.128` | 2 `STS.128` | 4 `STG.E.128` | 64 |
| shared memory, vectorized (128x64, 8x4) | 512 | 4 `LDG.E.128.CONSTANT` | 48 `LDS.128` | 3 `STS.128` | 8 `STG.E.128` | 88 |

## Observations

- Shared memory without vectorization is slower than vectorization without shared memory (12522 vs 22195 GFLOP/s at 2048^3). In the non-vectorized kernel the accumulator is loaded from and stored to global memory every K step (the `LDG.E`/`STG.E` above), because upstream hoisting only applies to vector transfers.
- Adding vectorization to the shared-memory kernel triples throughput at 2048^3 (12522 to 37017) and turns global and shared accesses into 128-bit instructions.
- 8x4 thread tiles in 128x64 blocks are 12% faster than 4x4 in 64x64 at 2048^3 and 4096^3, and equal at 1024^3. 128x128 blocks with 8x8 thread tiles (128 registers, 2 blocks per SM) are slower at 1024^3 and below, where 128x128 gives only 64 blocks for 188 SMs, and the fastest TensorForge variant at 4096^3.
- The fixed TensorForge configuration is ahead of KernelForge v6 at every shape (for example 41562 vs 33961 at 2048^3, 13626 vs 8287 at 777x1111x333) and ahead of Triton at 1024^3, 1000^3, and 777x1111x333. Triton is ahead at 4096^3 by 14% (`matmul`) and 13% (`mbr`) in raw throughput, and by about 1% at 2048^3.
- Fusing the epilogue costs nothing measurable in TensorForge (`mbr` vs `matmul` within 1%). cuBLAS followed by the epilogue kernel is 3% (2048^3) to 11% (777x1111x333) slower than cuBLAS alone.
- At 777x1111x333, TensorForge (13029, including padding copies to 896x1152x336) is 9% faster than cuBLAS + epilogue (11938) and 21% faster than Triton.
- At 256^3 and 512^3 cuBLAS stays well ahead of all generated kernels (for example 3048 vs 2456 at 256^3).

## Interpretation

TODO(Nirak)

## Open questions

- TensorForge's clock-adjusted efficiency at 2048^3 and 4096^3 (37 to 38%) is below Triton's (46 to 48%) and cuBLAS's (46 to 48%). Candidates are the absence of software pipelining (no overlap of the next tile's global loads with compute) and barrier count; not measured without counters.
- The padding copies' share of the time at non-multiple shapes is not measured separately.
