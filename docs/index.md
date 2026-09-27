# TensorForge documentation

Start with `report.md` for the whole project, or `../README.md` for the short version. `progress.md` is the running log (decisions, failures, open questions, and how to resume).

| Document | Contents |
|---|---|
| [report.md](report.md) | Project report: motivation, architecture, transformations, methodology, results, limitations |
| [progress.md](progress.md) | Running log: per-stage reports, decisions, open questions, resume steps |
| [dialect.md](dialect.md) | Semantics of the `tforge` ops |
| [stage0.md](stage0.md) | Toolchain, `tensorforge-opt`, lit infrastructure |
| [stage1.md](stage1.md) | `tforge` dialect and verifiers |
| [stage2.md](stage2.md) | Canonicalization and folding, with legality arguments |
| [stage3.md](stage3.md) | Lowering `tforge` to Linalg |
| [stage4.md](stage4.md) | CPU end to end and the scalar baseline |
| [stage5.md](stage5.md) | Fusion of matmul, bias_add, relu |
| [stage6.md](stage6.md) | CPU tiling and vectorization |
| [stage7.md](stage7.md) | GPU path: tiling, mapping, NVVM, driver-API runner |
| [stage8.md](stage8.md) | GPU memory hierarchy: shared memory, register tiles, 128-bit accesses |
| [stage9.md](stage9.md) | Cost model versus autotuning; ablation |
| [numerics.md](numerics.md) | E1: which transformations change floating-point results |
| [e2_a6000.md](e2_a6000.md) | E2: the Stage 9 comparison on an RTX A6000 |
| [compile_time.md](compile_time.md) | E3: compile time per pipeline, step, and pass |
| [debugging.md](debugging.md) | E4: `print-after-each` and source-location diagnostics |

Results are CSV files under `../results/` (`cpu/`, `gpu/`, `numerics/`, `compile/`); every row records its commit, toolchain versions, device, and Slurm job ID.
