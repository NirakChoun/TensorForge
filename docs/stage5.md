# Stage 5: fusion

## Question

Can `relu(matmul + bias)` be compiled so that the matmul and bias_add results are never materialized, and what does that change on the CPU? Yes: with upstream elementwise fusion plus TensorForge's tile-and-fuse pass, the kernel allocates no temporaries (down from two MxN buffers) and writes every tile of the result once, directly into the output. On this still-scalar code, run time changes by at most a few percent, because the matmul dominates.

## Design

The fused pipeline is `--tforge-cpu-pipeline="fuse-elementwise=1 tile-sizes=TM,TN"`:

| Step | Owner | Effect |
|---|---|---|
| `linalg-fuse-elementwise-ops` | upstream | bias_add and relu generics become one epilogue generic |
| `tforge-tile-and-fuse{tile-sizes=TM,TN}` | TensorForge policy, upstream mechanism | picks the epilogue as root, tiles its (M, N) loops, fuses fill and matmul into the loop (`scf::tileConsumerAndFuseProducersUsingSCF`) |
| `EpilogueIntoProducerInit` (inside the same pass) | TensorForge | rewrites the epilogue to update the matmul tile in place |
| `populateFoldTensorEmptyPatterns` (inside the pass) | upstream patterns | `extract_slice(tensor.empty)` becomes a tile-sized `tensor.empty` |
| `eliminate-empty-tensors` | upstream | the tile's `tensor.empty` is replaced by the output tile, so fill, matmul, and epilogue all write the output |
| `canonicalize` after bufferization | upstream | folds the loop-carried result buffer so `buffer-results-to-out-params` can use the caller's buffer |

The one TensorForge-specific rewrite is `EpilogueIntoProducerInit`:

```
%p = linalg.matmul ... outs(%acc)                     %p = linalg.matmul ... outs(%acc)
%r = linalg.generic ins(%p, %bias) outs(%init)   =>   %r = linalg.generic ins(%bias) outs(%p)
```

It applies when the generic is all-parallel, never reads its own init, reads `%p` with the identity map it writes, and `%p` has no other use. Each element is then read and overwritten at the same index, so updating `%p` in place is equivalent. Without it, the matmul tile is an input of the epilogue rather than part of its destination chain, and empty-tensor elimination cannot remove the tile temporary. `test/Transforms/tile-and-fuse.mlir` includes a negative case (an epilogue that accumulates into its init) that must not be rewritten.

Two pipeline details found while building this:

- CSE after tiling merges the fill's `tensor.empty` with the output's, which forces a full-size temporary plus a copy after bufferization. The fused pipeline does not run CSE between tiling and bufferization.
- CSE before tiling (the `reuse=1` variant) is an upstream-only way to get zero allocations: every op writes in place into the output, but the result is still written and re-read three times.

## Setup

Same machine, compiler, backend, harness, and statistics as Stage 4 (AMD EPYC 7532, job 24093215, 1 pinned thread, 10 warm-up + 100 reps, median). Workload `mbr` = `relu(A @ B + bias)` at five shapes. Commit 30cca26; results in `results/cpu/stage5.csv`.

| Variant | Pipeline options |
|---|---|
| baseline | none |
| reuse | `reuse=1` (CSE of `tensor.empty` before bufferization) |
| fuse-ew | `fuse-elementwise=1` |
| fused-32 | `fuse-elementwise=1 tile-sizes=32,32` |

## Results

All 20 kernels pass the FP64 bound with the same maximum error as the baseline (the K summation order is unchanged).

Temporary bytes allocated per call (bytes requested from the allocator, including 64 bytes of alignment slack per allocation):

| Shape (MxNxK) | baseline | reuse | fuse-ew | fused-32 |
|---|---|---|---|---|
| 64x64x64 | 32,896 | 0 | 16,448 | 0 |
| 127x129x65 | 131,192 | 0 | 65,596 | 0 |
| 256x256x256 | 524,416 | 0 | 262,208 | 0 |
| 250x330x170 | 660,128 | 0 | 330,064 | 0 |
| 512x512x512 | 2,097,280 | 0 | 1,048,640 | 0 |

Median time in ms (standard deviation in parentheses):

| Shape | baseline | reuse | fuse-ew | fused-32 |
|---|---|---|---|---|
| 64x64x64 | 0.206 (0.010) | 0.197 (0.007) | 0.190 (0.007) | 0.189 (0.006) |
| 127x129x65 | 0.823 (0.017) | 0.806 (0.014) | 0.791 (0.016) | 0.792 (0.014) |
| 256x256x256 | 20.17 (0.59) | 20.63 (0.67) | 21.71 (1.03) | 21.55 (0.17) |
| 250x330x170 | 12.47 (0.04) | 12.13 (0.05) | 12.25 (0.32) | 12.09 (0.04) |
| 512x512x512 | 318.8 (21.0) | 452.1 (3.8) | 317.5 (31.6) | 444.5 (4.2) |

IR evidence for 250x330x170 is in `results/cpu/stage5_ir/{baseline,fused}/` (input, Linalg, transformed, bufferized, LLVM dialect, assembly, expanded pipeline). Bufferized baseline:

```mlir
%alloc = memref.alloc() {alignment = 64 : i64} : memref<250x330xf32>
linalg.fill ins(%cst : f32) outs(%alloc : memref<250x330xf32>)
linalg.matmul ins(%arg0, %arg1 : ...) outs(%alloc : memref<250x330xf32>)
%alloc_0 = memref.alloc() {alignment = 64 : i64} : memref<250x330xf32>
linalg.generic ... ins(%alloc, %arg2 : ...) outs(%alloc_0 : ...)      // bias_add
linalg.generic ... ins(%alloc_0 : ...) outs(%arg3 : ...)             // relu
memref.dealloc %alloc
memref.dealloc %alloc_0
```

Bufferized fused-32 (every op writes the 32x32 output tile `%subview_1` of the caller's buffer `%arg3`):

```mlir
scf.for %arg4 = %c0 to %c250 step %c32 {
  scf.for %arg5 = %c0 to %c330 step %c32 {
    %subview   = memref.subview %arg0[%arg4, 0] [%0, 170] [1, 1]      // A rows
    %subview_0 = memref.subview %arg1[0, %arg5] [170, %1] [1, 1]      // B columns
    %subview_1 = memref.subview %arg3[%arg4, %arg5] [%0, %1] [1, 1]   // output tile
    linalg.fill ins(%cst : f32) outs(%subview_1 : ...)
    linalg.matmul ins(%subview, %subview_0 : ...) outs(%subview_1 : ...)
    linalg.generic ... ins(%subview_2 : ...) outs(%subview_1 : ...) {  // bias + relu in place
      %2 = arith.addf %out, %in : f32
      %3 = arith.maximumf %2, %cst : f32
```

## Observations

- Fusion removes both MxN temporaries (for example 2,097,280 bytes per call at 512^3). Elementwise fusion alone removes one.
- At the non-power-of-two shapes and at 64^3 and 127x129x65, the fused variant is 0 to 8% faster than the baseline (for example 12.09 vs 12.47 ms at 250x330x170). At 256^3, fuse-ew and fused-32 are 7% slower than the baseline.
- At 512^3 the variants split into two groups by where the matmul writes: into a temporary (baseline, fuse-ew: about 318 ms) or into the caller's output (reuse, fused-32: about 448 ms). Stage 4 measured a placement effect of this size for the same scalar loop nest (`docs/stage4.md`), so the 512^3 difference is not attributed to fusion.
- `reuse` also reaches zero allocations with upstream passes only, but it keeps three full passes over the output.

## Interpretation

TODO(Nirak)

## Open questions

- The 7% slowdown of the fused variants at 256^3 is not explained. The inner matmul loop is the same scalar (m, n, k) nest in all variants; the difference is that the fused kernel runs it per 32x32 tile.
