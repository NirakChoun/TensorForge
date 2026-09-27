# Stage 6: CPU tiling and vectorization

## Question

Can the fused `relu(matmul + bias)` be tiled and vectorized through upstream MLIR so the CPU code is competitive with a tuned BLAS, and which tile sizes work? Yes. Register tiles of 6x16 (K step 4), vectorized to `vector.contract` and lowered to 16-wide multiply-adds, run at 81 to 100 GFLOP/s on one Zen 2 core, against 0.6 to 2.8 GFLOP/s for the scalar code. For plain matmul this matches or beats single-threaded OpenBLAS at 4 of 5 shapes. Cache tiles that are not multiples of the register tile lose up to 60% of that, because every cache tile then carries a scalar remainder strip.

## Design

Pipeline: `--tforge-cpu-pipeline="fuse-elementwise=1 [tile-sizes=TM,TN] reg-tile=MR,NR,KR vectorize=1"`.

| Step | Owner | Effect |
|---|---|---|
| cache tiles `tforge-tile-and-fuse{tile-sizes=TM,TN}` (optional) | TensorForge policy, upstream mechanism | as in Stage 5 |
| register tiles `tforge-tile-and-fuse{tile-sizes=MR,NR tile-k=KR peel=1}` | TensorForge | the same pass applied again inside the cache tiles; the fused matmul's K loop is tiled by KR (`scf::tileUsingSCF`), and every created loop is peeled (`scf::peelForLoopAndSimplifyBounds`) so full tiles have static shapes |
| `tforge-vectorize` | TensorForge policy, upstream mechanism | `linalg::vectorize(..., createNamedContraction=true)` on every static linalg op with at most 4096 iteration points; dynamic remainder tiles are left scalar |
| `loop-invariant-subset-hoisting` | upstream | the 6x16 accumulator's read/write inside the K loop becomes a loop-carried `vector<6x16xf32>` |
| `convert-vector-to-scf`, `lower-vector-multi-reduction`, `convert-vector-to-llvm{vector-contract-lowering=outerproduct}` | upstream | `vector.contract` to outer products to `llvm.intr.fmuladd` on `vector<16xf32>` |
| `opt -O3`, `llc -O3 -mcpu=native` | upstream LLVM | x86 AVX2: `vfmadd231ps` on `ymm` registers |

Two first attempts did not produce FMAs, and one did not keep the accumulator in registers:

- The vectorizer's default output for a matmul tile is broadcast + multiply + `vector.multi_reduction`. The contract rewritten from it did not match the outer-product lowering, and the assembly had no FMAs. `createNamedContraction=true` emits a proper `vector.contract`.
- Upstream `linalg::hoistRedundantVectorTransfers` (after bufferization) refuses accumulators whose memref comes from `memref.subview`, which is always the case for a tile. Hoisting on tensors before bufferization with `loop-invariant-subset-hoisting` works.

## Setup

Same machine and method as Stage 4 (AMD EPYC 7532 Zen 2, job 24093215, 1 pinned thread, 10 warm-up + 100 reps, median; theoretical FMA peak per core 2 x 8 x 2 x 3.307 GHz = 105.8 GFLOP/s). Commit e6f9f8e.

- Sweep (`bench/stage6_sweep.sh`, `results/cpu/stage6_sweep.csv`): `mbr` at 5 shapes; register tiles {4x16x1, 6x16x1, 8x8x1, 6x16x4} x cache tiles {none, 32x32, 64x64, 96x96, 128x128}; plus the Stage 5 scalar fused kernel.
- Best configuration against the scalar baseline and NumPy/OpenBLAS (1 thread) for all four workloads (`results/cpu/stage6_best.csv`).

## Results

All 105 sweep kernels and all 36 best-configuration kernels pass correctness.

Sweep, GFLOP/s for `mbr` (best per shape in bold):

| Variant | 64x64x64 | 127x129x65 | 256x256x256 | 250x330x170 | 512x512x512 |
|---|---|---|---|---|---|
| scalar fused, 32x32 | 2.8 | 2.7 | 1.6 | 2.3 | 0.6 |
| reg 4x16x1, no cache tile | 80.2 | 70.7 | 81.9 | 57.7 | 59.1 |
| reg 4x16x1, 64x64 | 80.2 | 46.6 | 80.8 | 44.5 | 59.4 |
| reg 6x16x1, no cache tile | 87.4 | 86.8 | 97.9 | 63.7 | 67.8 |
| reg 6x16x1, 32x32 | 90.6 | 38.8 | 91.2 | 30.9 | 63.6 |
| reg 6x16x1, 64x64 | **91.7** | 39.4 | 93.5 | 30.2 | 66.2 |
| reg 6x16x1, 96x96 | 87.5 | 67.7 | 67.8 | 44.3 | 63.3 |
| reg 6x16x1, 128x128 | 85.5 | 76.7 | 92.4 | 46.7 | 66.4 |
| reg 8x8x1, no cache tile | 70.0 | 73.7 | 74.7 | 76.4 | 51.0 |
| reg 8x8x1, 64x64 | 68.9 | 36.2 | 70.8 | 61.3 | 51.5 |
| reg 6x16x4, no cache tile | 90.2 | **87.9** | **102.5** | **86.3** | **87.8** |
| reg 6x16x4, 32x32 | 85.4 | 39.3 | 93.8 | 29.8 | 81.3 |
| reg 6x16x4, 64x64 | 88.9 | 39.6 | 100.2 | 30.9 | 85.4 |
| reg 6x16x4, 96x96 | 90.4 | 69.5 | 72.5 | 46.8 | 75.0 |
| reg 6x16x4, 128x128 | 90.2 | 80.0 | 99.7 | 47.2 | 86.8 |

The full 21 x 5 table is in the CSV.

Best configuration (reg 6x16x4, no cache tile) in a separate run, GFLOP/s or GB/s:

| Workload | Shape | Scalar baseline | Vectorized | NumPy (OpenBLAS, 1 thread) |
|---|---|---|---|---|
| matmul | 64x64x64 | 2.81 | 94.8 | 50.4 |
| matmul | 127x129x65 | 2.73 | 92.0 | 60.9 |
| matmul | 256x256x256 | 1.68 | 99.9 | 87.6 |
| matmul | 250x330x170 | 2.33 | 87.0 | 82.4 |
| matmul | 512x512x512 | 0.59 | 87.5 | 93.8 |
| mbr | 64x64x64 | 2.70 | 97.5 | 29.6 |
| mbr | 127x129x65 | 2.66 | 81.3 | 39.2 |
| mbr | 256x256x256 | 1.58 | 100.2 | 74.6 |
| mbr | 250x330x170 | 2.24 | 85.4 | 66.4 |
| mbr | 512x512x512 | 0.90 | 86.1 | 86.2 |
| relu (GB/s) | 1024x1024 | 12.6 | 52.8 | 11.0 |
| relu (GB/s) | 4096x4096 | 11.5 | 22.5 | 10.5 |
| add (GB/s) | 1024x1024 | 31.3 | 50.0 | 71.1 |
| add (GB/s) | 4096x4096 | 20.4 | 23.8 | 23.7 |

NumPy `mbr` is three separate calls (matmul, add, maximum), so it includes two extra passes over the output that the fused kernel does not make.

### Generated-code evidence

`results/cpu/stage6_ir/r6x16x4/` holds every step for `mbr` 250x330x170. Before bufferization, the K loop carries the accumulator as a vector and uses 6x4 by 4x16 contractions:

```mlir
%21 = scf.for %arg7 = %c0 to %c168 step %c4 iter_args(%arg8 = %cst_2) -> (vector<6x16xf32>) {
  %29 = vector.transfer_read %extracted_slice_23[%c0, %c0], %cst_3 {in_bounds = [true, true]} : tensor<6x4xf32>, vector<6x4xf32>
  %30 = vector.transfer_read %extracted_slice_24[%c0, %c0], %cst_3 {in_bounds = [true, true]} : tensor<4x16xf32>, vector<4x16xf32>
  %31 = vector.contract {... kind = #vector.kind<add>} %29, %30, %arg8 : vector<6x4xf32>, vector<4x16xf32> into vector<6x16xf32>
  scf.yield %31 : vector<6x16xf32>
```

(K = 170 runs 42 full steps of 4; the peeled remainder handles the last 2.) The innermost loop of the assembly zeroes 12 `ymm` accumulators and then does, per K step, 2 vector loads of B, 6 broadcasts of A, and 12 `vfmadd231ps`:

```
.LBB0_3:
	vmovups	(%r12), %ymm12
	vbroadcastss	-3384(%rdi,%r15,4), %ymm13
	vmovups	32(%r12), %ymm14
	vbroadcastss	28(%rdi,%r15,4), %ymm15
	vfmadd231ps	%ymm12, %ymm13, %ymm0   # ymm0 = (ymm13 * ymm12) + ymm0
	...
```

The kernel contains 224 `vfmadd231ps` in total; the scalar baseline's assembly contains no `ymm` instructions. `llvm-mca -mcpu=znver2` on that loop (84 instructions, 48 FMAs for 4 K steps; `mca_inner_loop.txt`) predicts 24.0 cycles per iteration, which is 2 FMAs per cycle, the Zen 2 FMA throughput limit.

## Observations

- Vectorization is worth 30x to 150x over the scalar fused kernel (for example 2.3 to 86.3 GFLOP/s at 250x330x170).
- 6x16 register tiles beat 4x16 and 8x8 at every shape. 6x16 uses 12 of the 16 `ymm` registers for accumulators; 4x16 uses 8 and 8x8 uses 8.
- KR = 4 is faster than KR = 1 for 6x16 at the larger shapes (87.8 vs 67.8 GFLOP/s at 512^3) and about equal at 64^3.
- Adding cache tiles never helped except at 64x64x64 (91.7 vs 90.2), and hurt most when the cache tile is not a multiple of the register tile: at 127x129x65 and 250x330x170, 32x32 and 64x64 cache tiles cut throughput by 50 to 65%. With MR = 6, a 32- or 64-row cache tile leaves a 2- or 4-row remainder in every cache tile, and those rows run as scalar code.
- The best matmul kernel reaches 99.9 GFLOP/s at 256^3, 94% of the theoretical per-core peak, and is 7% slower than OpenBLAS at 512^3.
- For `add`, the vectorized kernel is slower than NumPy at 999x1001 and 1024x1024 (39 to 50 vs 71 to 72 GB/s); both reach about 24 GB/s at 4096x4096. For `relu`, it is 2x to 5x faster than NumPy.
- `err/bound` for `mbr` 512^3 changes from 0.00726 (scalar) to 0.00777 (vectorized): the fused multiply-adds round differently (`docs/numerics.md`).

## Interpretation

TODO(Nirak)

## Open questions

- The vectorized `add` is 30 to 45% slower than NumPy at 1024x1024 even though both are single passes over memory. The 6x16 register tile makes each row access 16 floats wide; a 1-D tiling along the contiguous dimension would likely stream better. Not tested.
- Cache tiling was only swept at sizes that are not multiples of 6. Sizes like 48x48 or 96x64 (multiples of 6 and 16) were not tested, so this sweep does not show whether cache tiling helps when it creates no remainders.
