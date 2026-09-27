# E1: numerics of TensorForge transformations

Of the TensorForge transformations, only FMA contraction changes floating-point results. Tiling in M and N, fusion of the bias and relu epilogue, register tiling, the K step of the register tile (KR), and the GPU K tile (BK) leave every output bit unchanged, because none of them reorders the K reduction. With contraction, 40% to 91% of output elements differ in the last bits from the unfused-multiply-add evaluation. Every variant stays at most 1.5% of the worst-case FP64-derived error bound.

## Question

Which TensorForge transformations change results relative to the reference evaluation order of the `tforge` semantics (sequential k, separate multiply and add), and how large is the error against FP64?

## Setup

`bench/e1_numerics.py`; results in `results/numerics/e1.csv` (job 24105050; commit e5e1490 plus the E1 script, which is committed with the results). Inputs are uniform random f32 (the Stage 4 generator, seed 1234), the same for every variant. Workloads: `matmul` and fused `mbr = relu(A @ B + bias)`. Shapes: 256^3, 1000^3, 777x1111x333, 512x512x4096. CPU variants ran on the GPU node's AMD EPYC 9554.

| Variant | Pipeline | Multiply-add in the generated code |
|---|---|---|
| cpu-scalar | `--tforge-cpu-pipeline` (Stage 4 baseline) | `vmulss` + `vaddss`, no FMA |
| cpu-fused-tiled-32 | fused, 32x32 tiles, scalar | `vmulss` + `vaddss`, no FMA |
| cpu-vec-kr1, cpu-vec-kr4 | fused, register tile 6x16, KR 1 or 4, vectorized | `vfmadd` (from `vector.fma` in the outer-product lowering) |
| gpu-naive | one output per thread | `FFMA` (from `llc -fp-contract=fast`) |
| gpu-staged-bk8/16/32 | 128x64 blocks, 8x4 thread tiles, shared memory, vectorized | `FFMA` |
| numpy-openblas | NumPy float32, OpenBLAS, 1 thread | library |
| cublas | `cublasSgemm`, FP32, then the Stage 7 epilogue kernel | library |

Instruction evidence: `objdump` of the CPU objects and `cuobjdump -sass` of the cubins at 256^3 (`build/artifacts/{cpu,gpu}/e1/`): cpu-scalar 0 `vfmadd`; cpu-vec-kr4 40 `vfmadd`, 0 `vmulps`; gpu-naive 64 `FFMA`, 0 `FMUL`; gpu-staged-bk16 512 `FFMA`, 0 `FMUL`.

Error metrics: max |x - x64| over all elements, and max |x - x64| / bound with bound = gamma_{K+1} (|A||B| + |bias|) (gamma_K for `matmul`), which holds for any summation order and with or without FMA.

## Results

Fraction of output elements that differ bitwise from cpu-scalar (the reference order without FMA) and from gpu-naive (sequential k with FMA), and max error / bound:

| Workload, shape | Variants | vs cpu-scalar | vs gpu-naive | max err / bound |
|---|---|---|---|---|
| matmul 1000^3 | cpu-scalar, cpu-fused-tiled-32 | 0 | 0.872 | 0.0041 |
| | cpu-vec-kr1/kr4, gpu-naive, gpu-staged-bk8/16/32 | 0.872 | 0 | 0.0041 |
| | numpy-openblas | 0.944 | 0.935 | 0.0025 |
| | cublas | 0.950 | 0.949 | 0.0014 |
| matmul 512x512x4096 | no FMA (2 variants) | 0 | 0.911 | 0.0012 |
| | FMA, sequential k (6 variants) | 0.911 | 0 | 0.0012 |
| | numpy-openblas | 0.975 | 0.975 | 0.00022 |
| | cublas | 0.975 | 0.975 | 0.00029 |
| matmul 256^3 | FMA (6 variants), numpy-openblas | 0.813 | 0 | 0.0136 |
| | cublas | 0.905 | 0.901 | 0.0054 |
| matmul 777x1111x333 | FMA (6 variants), numpy-openblas, cublas | 0.828 | 0 | 0.0144 |
| mbr 1000^3 | FMA (6 variants) | 0.432 | 0 | 0.0037 |
| | numpy-openblas / cublas | 0.469 / 0.472 | 0.464 / 0.471 | 0.0024 / 0.0014 |
| mbr 512x512x4096 | FMA (6 variants) | 0.456 | 0 | 0.00094 |
| | numpy-openblas / cublas | 0.489 / 0.489 | 0.489 / 0.489 | 0.00022 / 0.00030 |

Max absolute error against FP64 ranges from 1.4e-5 (256^3) to 3.0e-4 (`matmul`, K = 4096) for TensorForge variants, and 5.3e-6 to 7.5e-5 for the libraries. All rows are in `results/numerics/e1.csv`.

## Observations

- Within each group (no FMA; FMA with sequential k), every TensorForge variant is bitwise identical to the others at every shape. Tiling M and N, fusion, KR, BK, shared-memory staging, and vectorization do not change results.
- FMA contraction is the only TensorForge change that alters bits. At the Stage 4 tolerance it is not visible: max error / bound changes by at most 7% relative (0.0138 to 0.0129 at `mbr` 256^3).
- For `mbr`, about half as many elements differ as for `matmul`: relu maps every negative sum to exactly 0 regardless of rounding.
- NumPy/OpenBLAS is bitwise identical to TensorForge's FMA variants at K = 256 and K = 333, and differs at K = 1000 and K = 4096. cuBLAS is identical at 777x1111x333 only. Where they differ, both libraries have smaller error than TensorForge, which is consistent with a K reduction split into blocks, although the libraries' kernels were not inspected.
- TensorForge's error grows with K: at K = 4096 its max error is 3.2x to 5.5x the libraries'.

## Interpretation

TODO(Nirak)

## Open questions

- A split-K or blocked K reduction would reduce TensorForge's error at large K and would also change bits; it was not implemented, so the trade-off was not measured.
- The CPU pipeline gets FMA only through the vector lowering; scalar CPU code keeps separate multiply and add, so scalar CPU and GPU kernels differ bitwise. Whether to contract in the scalar CPU path too, so that all TensorForge kernels agree, is undecided.
