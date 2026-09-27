# TensorForge progress log

Current state: Stage 4 complete. Next: Stage 5 (fusion).

## How to resume

1. `ssh hive hostname` returns `login2`.
2. `cd ~/TensorForge && git log --oneline -30 && git status`.
3. `sacct -u $USER --starttime today` for unprocessed jobs; logs are in `~/TensorForge/logs/` (not committed).
4. Development runs inside one held allocation: `scripts/devjob.sh start cpu 12` (or `gpu`), then `scripts/in_job.sh <cmd>` (add `TF_BG=<name>` to run in the background with output in `logs/<name>.log`). `scripts/devjob.sh stop` when done. Only one Slurm job at a time.
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

## Open questions

- CMake `ZLIB_LIBRARY` not found warning during configure (no effect so far).
- Stage 2: the `+0.0` fold only recognizes a direct `relu` producer; a "never -0.0" analysis would cover more cases.
- Stage 4: scalar 512^3 kernels vary by up to 18% with output-buffer placement (446 vs 377 ms at 0 vs 16 byte offset); mechanism not attributed (no hardware counters).
