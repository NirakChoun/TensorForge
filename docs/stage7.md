# Stage 7: GPU path

## Question

Can the same `tforge` program be compiled to an sm_120 kernel through upstream MLIR (tiling to `scf.forall`, mapping to blocks and threads, NVVM, PTX, `ptxas`) and run correctly from a small driver-API runner? Yes. The fused `relu(matmul + bias)` kernel with one output per thread is correct at every tested shape, including 1000^3 and 777x1111x333. It runs at 2.3 to 3.6 TFLOP/s (about 3% of FP32 peak at the median SM clock), against 13 to 52 TFLOP/s for cuBLAS.

## Design

`--tforge-gpu-pipeline="block-tile=BM,BN thread-tile=TM,TN"` (`lib/Pipelines/Pipelines.cpp`):

| Step | Owner | Effect |
|---|---|---|
| `convert-tforge-to-linalg`, `linalg-fuse-elementwise-ops` | TensorForge, upstream | as on CPU |
| `tforge-gpu-tile` | TensorForge policy, upstream mechanism | applies the in-place epilogue rewrite (Stage 5), then generates and runs a Transform script: `tile_using_forall` of the root with `tile_sizes [BM, BN]` mapped to `#gpu.block<y, x>`, `fuse_into_containing_op` for matmul and fill, `tile_using_forall` with `num_threads [BM/TM, BN/TN]` mapped to `#gpu.thread<y, x>`, and fusion of the producers into the thread loop |
| `eliminate-empty-tensors`, `one-shot-bufferize`, `buffer-results-to-out-params`, `cse`, `canonicalize` | upstream | in-place bufferization; CSE merges identical subviews so the self-copies of `parallel_insert_slice` fold away |
| `tforge-gpu-map` | TensorForge policy, upstream mechanism | generated script: `transform.gpu.map_forall_to_blocks ... generate_gpu_launch`, `transform.gpu.map_nested_forall_to_threads block_dims = [BN/TN, BM/TM, 1]` |
| `convert-linalg-to-loops`, `gpu-kernel-outlining`, `expand-strided-metadata`, `lower-affine`, `convert-scf-to-cf`, `convert-gpu-to-nvvm{use-bare-ptr-memref-call-conv}` | upstream | per-thread loops, outlined kernel, NVVM with one pointer per buffer |
| `tforge-gpu-extract` | TensorForge | keeps the device module, records `tforge.launch = {kernel, grid, block, args}`, marks kernel pointers `noalias` |
| `mlir-translate`, `opt -O3 -mcpu=sm_120`, `llc -O3 -mcpu=sm_120 -fp-contract=fast` | upstream LLVM | PTX |
| `ptxas -O3 -arch=sm_120 -v`, `cuobjdump -sass` | CUDA 13.3 | cubin, resource report, SASS |

Why a Transform script inside a pass: upstream exposes block/thread mapping only as Transform ops (the C++ helper for blocks requires a transform-op handle). Generating the script from pipeline options keeps the pipeline registered and parameterized. `print-script=1` prints both scripts; `test/Transforms/gpu-tile-script.mlir` checks them.

Kernel ABI: the TensorForge program's buffers are passed as distinct, non-overlapping device pointers. That is what makes marking them `noalias` legal. Without it, LLVM cannot keep the accumulator in a register across the K loop, because a store to C might alias a later load of A or B.

`tforge-gpu-bench` (`runners/gpu/tforge-gpu-bench.cu`, built with nvcc 13.3 and GCC 11) uses the CUDA driver API: `cuModuleLoadData`, `cuLaunchKernel` with the recorded grid, block, and arguments. It times with CUDA events as KernelForge's harness does: 10 warm-up launches, 100 timed, median, optional L2 flush by a 256 MiB write before each rep. After each rep it samples the SM clock and power with NVML. It also reports registers, local memory, static shared memory, and occupancy from `cuFuncGetAttribute` and `cuOccupancyMaxActiveBlocksPerMultiprocessor`. `--mode cublas` runs `cublasSgemm` in the default math mode (FP32, no TF32), followed for `mbr` by a separate bias+relu kernel.

Correctness: every kernel is checked against an FP64 reference with the same `gamma_{K+1}` bound as on the CPU, and the maximum difference from cuBLAS on the same inputs is reported.

Two backend fixes were needed before the first measurement:

- With `llc` alone, loads were generic (`LD.E`) and the accumulator was stored to C every K step. `opt -O3` (address-space inference, LICM with `noalias`) gives `LDG.E.CONSTANT` and a single store.
- `llc` does not fuse `fmul` + `fadd` without FP contraction. `-fp-contract=fast` (the nvcc default) gives `FFMA`.

## Setup

| Item | Value |
|---|---|
| GPU | NVIDIA RTX PRO 6000 Blackwell Max-Q Workstation Edition (sm_120, 188 SMs), driver 13.0 |
| Node / job | hive-dc-7-4-58, Slurm job 24105050 (one GPU, 8 CPUs) |
| Toolchain | MLIR/LLVM 23.1.2, CUDA 13.3 (`ptxas`, cuBLAS) |
| Commit | 255fa32 |
| Timing | 10 warm-up + 100 reps, CUDA events, median; no L2 flush (compute-bound GEMM, as in KernelForge's SGEMM runs) |
| Clock adjustment | % of FP32 peak at the median SM clock, peak = 188 x 128 x 2 x clock (KernelForge convention) |
| Variants | one output per thread (`thread-tile=1,1`), block tiles 16x16, 8x32, 32x8, 32x32; cuBLAS |

## Results

70/70 kernels pass the FP64 bound. The largest difference from cuBLAS is 3.6e-4 at 4096^3 (both are within the bound; `results/gpu/stage7.csv`).

`mbr` = `relu(A @ B + bias)`, GFLOP/s (% of FP32 peak at the median SM clock):

| Variant | 256^3 | 512^3 | 1024^3 | 2048^3 | 4096^3 | 1000^3 | 777x1111x333 |
|---|---|---|---|---|---|---|---|
| naive 16x16 | 724 (0.66%) | 2999 (2.73%) | 3321 (3.04%) | 3596 (3.29%) | 3580 (3.19%) | 2897 (2.58%) | 2564 (2.34%) |
| naive 8x32 | 726 (0.66%) | 2988 (2.72%) | 3301 (3.01%) | 3574 (3.18%) | 3515 (3.13%) | 2882 (2.63%) | 2560 (2.33%) |
| naive 32x8 | 725 (0.66%) | 2939 (2.68%) | 3282 (2.99%) | 3573 (3.18%) | 3605 (3.21%) | 2935 (2.67%) | 2397 (2.18%) |
| naive 32x32 | 725 (0.66%) | 1686 (1.54%) | 2261 (2.06%) | 2436 (2.17%) | 2436 (2.17%) | 2036 (1.86%) | 2010 (1.83%) |
| cuBLAS + epilogue kernel | 2233 (2.04%) | 12691 (11.57%) | 35044 (31.94%) | 50498 (44.99%) | 49553 (45.16%) | 32484 (28.94%) | 12127 (11.05%) |

Plain `matmul` gives the same TensorForge numbers to within 1% (the fused epilogue costs nothing measurable at this level); cuBLAS alone is 37449 GFLOP/s at 1024^3 and 52411 at 2048^3 (full table in the CSV). Median SM clocks were 2272 to 2332 MHz, board power about 70 W.

### Generated-code evidence

`results/gpu/stage7_ir/naive-16x16_mbr_1024/` holds the tensor IR before bufferization, the device module, PTX, `ptxas -v` output, and SASS. The inner loop in PTX:

```
ld.global.nc.b32 	%r6, [%rd41];
ld.global.nc.b32 	%r7, [%rd40];
fma.rn.f32 	%r11, %r6, %r7, %r11;
```

and one `st.global.b32` after the loop (bias add and `max` applied in registers). `ptxas`: 18 registers, 0 bytes stack, no spills, 1 barrier. In SASS, the loop has two `LDG.E.CONSTANT` and one `FFMA` per K step.

## Observations

- One output per thread reaches about 3% of FP32 peak for all block shapes with 256 threads; the 1024-thread 32x32 block is about 30% slower (1 block per SM, 67% theoretical occupancy).
- At 256^3 every TensorForge variant takes about 0.046 ms, roughly the launch-dominated regime.
- cuBLAS followed by a separate epilogue kernel is 3 to 27% slower than cuBLAS alone (for example 12127 vs 13303 GFLOP/s at 777x1111x333); the TensorForge kernel fuses the epilogue at no measurable cost.
- `map_nested_forall_to_threads` inserts a barrier after the thread loop (`used 1 barriers`), which this kernel does not need.

## Interpretation

TODO(Nirak)

## Open questions

- `cuFuncGetAttribute` reports 22 registers for some kernels where `ptxas -v` reports 18 for the same configuration at a different shape; the CSV records the driver's value. Not investigated.
