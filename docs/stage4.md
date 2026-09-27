# Stage 4: CPU end-to-end

## Question

Can `tforge` programs be compiled to native CPU code, run, and verified against NumPy, and how fast is the untransformed baseline? Yes: all four workloads at 18 shapes (including non-multiples of 16) match NumPy/FP64 within documented tolerances. The baseline is scalar code: 0.6 to 2.8 GFLOP/s for matmul against 44 to 92 GFLOP/s for single-threaded OpenBLAS.

## Design

TensorForge:

- `--tforge-cpu-pipeline` (`lib/Pipelines/Pipelines.cpp`): a registered pipeline assembled from pass names, printable with `--dump-pass-pipeline`.
- `tforge-cpu-bench` (`runners/cpu/`): a C++ harness that `dlopen`s a compiled kernel, calls `_mlir_ciface_entry`, times it, and counts the bytes the kernel allocates. All harness buffers are 64-byte aligned.
- `python/tforge_cpu.py`, `bench/cpu_bench.py`: workload generation, compilation, correctness checks, timing, CSV output.

Upstream MLIR supplies every pass in the pipeline:

| Step | Passes |
|---|---|
| tforge to Linalg on tensors | `convert-tforge-to-linalg` (TensorForge), `canonicalize` |
| Bufferization | `one-shot-bufferize{bufferize-function-boundaries, identity-layout-map}`, `canonicalize`, `buffer-results-to-out-params{hoist-static-allocs, modify-public-functions}`, `buffer-deallocation-pipeline` |
| Loops | `convert-linalg-to-loops`, `expand-strided-metadata`, `lower-affine`, `convert-scf-to-cf` |
| LLVM dialect | `llvm-request-c-wrappers`, `finalize-memref-to-llvm{use-generic-functions}`, `convert-{math,arith,cf,func,index}-to-llvm`, `reconcile-unrealized-casts` |

Backend: `mlir-translate --mlir-to-llvmir`, then `opt -O3`, then `llc -O3 -mcpu=native -relocation-model=pic`, then a shared object.

Design choices:

- **ABI.** Function results become caller-provided out-params, and the static result allocation is replaced by the out-param. The harness owns the output buffer, so a call allocates only true temporaries.
- **Allocation accounting.** `use-generic-functions` routes every heap allocation through `_mlir_memref_to_llvm_alloc`, which the harness defines (linked `-rdynamic`) and counts. The count is bytes requested from the allocator, which includes 64 bytes of alignment slack per allocation.
- **No CSE before bufferization.** CSE merges the identical `tensor.empty` inits of consecutive ops. One-shot bufferization then writes every op in place into one buffer, which is a real optimization but would hide the unfused baseline. Stage 5 measures it as a separate variant.

## Setup

| Item | Value |
|---|---|
| CPU | AMD EPYC 7532 (Zen 2), 2 sockets x 32 cores, 1 thread per core, max 3307 MHz; L2 512 KiB per core, L3 16 MiB per CCX (`results/cpu/lscpu_24093215.txt`) |
| Node / job | hive-as-11-3-39, Slurm job 24093215 (8 CPUs allocated, node shared with other jobs) |
| Threads | 1; the harness pins itself to the first CPU of the allocation |
| Compiler | MLIR/LLVM 23.1.2; `opt -O3`, `llc -O3 -mcpu=native` |
| Timing | 10 warm-up + 100 timed calls, `steady_clock` per call, median reported; caches warm (inputs reused) |
| Baseline | NumPy 2.5.3 with OpenBLAS 0.3.34 (`libopenblasp-r0.3.34.so`), `OPENBLAS_NUM_THREADS=1`, output preallocated |
| Correctness | `add`, `relu`: bit-exact against NumPy float32. `matmul`, `mbr`: `|C - C64| <= gamma_{K+1} (|A||B| + |bias|)`, `gamma_j = j u / (1 - j u)`, `u = 2^-24`, which holds for any summation order; inputs uniform in [-1, 1] |

`mbr` is `relu(A @ B + bias)`. Shapes are MxN for elementwise ops and MxNxK for matmul.

## Results

Correctness: 36/36 kernel checks pass. Elementwise results are bit-exact; the largest matmul `err/bound` is 0.049 (127x129x65). Full rows, including relu 33x17, are in `results/cpu/stage4.csv` (commit 30cca26, job 24093215). An earlier run with a 16-byte-aligned output buffer is kept in `results/cpu/superseded/` and not used.

| Workload | Shape | TensorForge median (ms) | TensorForge | NumPy median (ms) | NumPy | Temp bytes/call |
|---|---|---|---|---|---|---|
| add | 33x17 | 0.0003 | 24.9 GB/s | 0.0008 | 8.6 GB/s | 0 |
| add | 999x1001 | 0.390 | 30.7 GB/s | 0.174 | 68.9 GB/s | 0 |
| add | 1024x1024 | 0.411 | 30.7 GB/s | 0.184 | 68.3 GB/s | 0 |
| add | 4096x4096 | 10.06 | 20.0 GB/s | 8.55 | 23.6 GB/s | 0 |
| relu | 999x1001 | 0.621 | 12.9 GB/s | 0.730 | 11.0 GB/s | 0 |
| relu | 1024x1024 | 0.653 | 12.9 GB/s | 0.765 | 11.0 GB/s | 0 |
| relu | 4096x4096 | 11.69 | 11.5 GB/s | 14.33 | 9.4 GB/s | 0 |
| matmul | 64x64x64 | 0.189 | 2.78 GFLOP/s | 0.0118 | 44.3 GFLOP/s | 0 |
| matmul | 127x129x65 | 0.779 | 2.73 GFLOP/s | 0.0348 | 61.3 GFLOP/s | 0 |
| matmul | 256x256x256 | 20.15 | 1.67 GFLOP/s | 0.381 | 88.0 GFLOP/s | 0 |
| matmul | 250x330x170 | 12.19 | 2.30 GFLOP/s | 0.337 | 83.3 GFLOP/s | 0 |
| matmul | 512x512x512 | 448.7 | 0.60 GFLOP/s | 2.93 | 91.5 GFLOP/s | 0 |
| mbr | 64x64x64 | 0.194 | 2.70 GFLOP/s | 0.0201 | 26.1 GFLOP/s | 32896 |
| mbr | 127x129x65 | 0.801 | 2.66 GFLOP/s | 0.0542 | 39.3 GFLOP/s | 131192 |
| mbr | 256x256x256 | 20.36 | 1.65 GFLOP/s | 0.453 | 74.1 GFLOP/s | 524416 |
| mbr | 250x330x170 | 12.46 | 2.25 GFLOP/s | 0.420 | 66.7 GFLOP/s | 660128 |
| mbr | 512x512x512 | 297.3 | 0.90 GFLOP/s | 3.14 | 85.5 GFLOP/s | 2097280 |

Generated-code evidence: the baseline assembly (`build/artifacts/cpu/stage4/baseline/*/k.s`) contains no `ymm` register uses for add, relu, or matmul; arithmetic is scalar (`vaddss`, `vmaxss`, `vmovss`). `opt -O3` did not auto-vectorize these loops.

## Observations

- The baseline is scalar. Matmul throughput falls as the working set grows: 2.78 GFLOP/s at 64^3, 1.67 at 256^3, 0.60 at 512^3. The loop order from `convert-linalg-to-loops` is (m, n, k), so the inner loop walks a column of B with stride N.
- `mbr` allocates two MxN temporaries per call (matmul result and bias_add result), for example 2 x (512 x 512 x 4 + 64) = 2,097,280 bytes at 512^3.
- For `add` at 33x17, the compiled kernel is faster than NumPy (0.27 us vs 0.8 us) because NumPy's per-call overhead dominates. At 4096x4096 both are memory bound at 20 to 24 GB/s.
- TensorForge `relu` is faster than NumPy `maximum` at every measured size (12.9 vs 11.0 GB/s at 1024x1024).
- At 512^3, `matmul` (448.7 ms) is slower than `mbr` (297.3 ms) although `mbr` does strictly more work with the same loop nest. The difference is where the matmul writes: the caller's output buffer for `matmul`, a separately allocated temporary for `mbr`. A controlled run of the same `matmul` kernel with the output shifted by 0, 16, and 32 bytes from a 64-byte boundary took 446.4, 377.1, and 387.3 ms (20 reps each, `results/cpu/align_experiment_24093215.log`). The scalar 512^3 loop nest is sensitive to the relative placement of its power-of-two-sized arrays, so 512^3 comparisons across variants include a placement effect of this size.

## Interpretation

TODO(Nirak)

## Open questions

- The 512^3 placement sensitivity was measured but not attributed to a specific mechanism (L1 set conflicts or 4K aliasing between the B column walk and the output are candidates). Hardware counters are unavailable on Hive, so this is not pursued.
