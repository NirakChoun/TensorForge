# E3: compile time

Compiling one fused kernel end to end takes 0.18 to 0.29 s, and the time does not depend on the problem size. The MLIR pipeline itself runs in 6 to 27 ms; process start-up and the LLVM and CUDA tools take the rest. The most expensive configuration (staged GPU kernel) costs 0.26 s; the cheapest (naive GPU kernel) costs 0.18 s.

## Setup

`bench/e3_compile_time.py`; results in `results/compile/e3.csv`, per-pass MLIR timings in `results/compile/timing_*.txt` (`--mlir-timing`). Job 24105050 on an AMD EPYC 9554 node (8 CPUs allocated); commit e5e1490 plus the E3 script, which is committed with the results. Workload: fused `mbr`. Each step runs once untimed and then 5 times; the table reports the median wall time, including process start-up. Steps run one after another, each as its own process, as in the benchmark drivers.

| Configuration | Pipeline options |
|---|---|
| cpu-baseline | `--tforge-cpu-pipeline` |
| cpu-fused-vectorized | `fuse-elementwise=1 reg-tile=6,16,4 vectorize=1` |
| gpu-naive | `block-tile=16,16 thread-tile=1,1` |
| gpu-staged | `block-tile=128,64 thread-tile=8,4 tile-k=16 promote=1 vectorize=1` |

## Results

Median seconds per step at 1024^3:

| Configuration | tensorforge-opt | mlir-translate | opt -O3 | llc -O3 | link / ptxas | Total |
|---|---|---|---|---|---|---|
| cpu-baseline | 0.031 | 0.061 | 0.036 | 0.036 | 0.074 (link) | 0.238 |
| cpu-fused-vectorized | 0.050 | 0.059 | 0.039 | 0.039 | 0.103 (link) | 0.289 |
| gpu-naive | 0.047 | 0.052 | 0.035 | 0.037 | 0.025 (ptxas) | 0.196 |
| gpu-staged | 0.064 | 0.059 | 0.041 | 0.043 | 0.053 (ptxas) | 0.261 |

Totals at 256^3, 1024^3, and 4096^3: cpu-baseline 0.256, 0.238, 0.254 s; cpu-fused-vectorized 0.291, 0.289, 0.281 s; gpu-naive 0.175, 0.196, 0.178 s; gpu-staged 0.259, 0.261, 0.253 s.

MLIR pipeline time from `--mlir-timing` at 1024^3, and its largest passes:

| Configuration | MLIR pipeline | Largest passes (share of pipeline time) |
|---|---|---|
| cpu-baseline | 6.2 ms | finalize-memref-to-llvm 10% |
| cpu-fused-vectorized | 15.6 ms | convert-vector-to-llvm 11%, tforge-tile-and-fuse 5% |
| gpu-naive | 11.8 ms | tforge-gpu-tile 12%, tforge-gpu-map 10%, convert-gpu-to-nvvm 8% |
| gpu-staged | 27.1 ms | convert-gpu-to-nvvm 19%, tforge-gpu-map 16%, tforge-gpu-tile 6% |

## Observations

- Compile time is flat in problem size, because shapes are static and only change constants in the IR.
- `tensorforge-opt` takes 31 to 64 ms as a process, but its passes take 6 to 27 ms; the rest is start-up, parsing, and printing.
- The staged GPU pipeline's passes take 4.4x as long as the CPU baseline's, and `ptxas` takes twice as long for the staged kernel (0.053 vs 0.025 s), consistent with its larger unrolled body (512 vs 64 `FFMA` in the same configurations at 256^3, `docs/numerics.md`).
- Through Python (`tforge_gpu.compile_kernel`, which also runs `cuobjdump` and writes artifacts), one staged kernel at 2048^3 took 0.60 s (32x32, 4x4, BK 8) to 0.87 s (64x64, 8x8, BK 32) in a single measurement each.

## Interpretation

TODO(Nirak)

## Open questions

- Stage 9 reports 43 to 74 s per shape for the cost model (compiling 105 configurations 8 at a time, then 105 occupancy queries one after another, each a new process with a CUDA context). With single compiles at 0.6 to 0.9 s, compilation alone does not obviously account for that time; the split between compilation and occupancy queries was not measured.
