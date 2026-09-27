# TensorForge progress log

Current state: Stage 0 complete. Next: Stage 1 (`tforge` dialect).

## How to resume

1. `ssh hive hostname` returns `login2`.
2. `cd ~/TensorForge && git log --oneline -30 && git status`.
3. `sacct -u $USER --starttime today` for unprocessed jobs; logs are in `~/TensorForge/logs/` (not committed).
4. Build and test: `scripts/run_job.sh cpu env JOBS=8 scripts/build.sh` (one Slurm job at a time).

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

## Stage 0 report

Toolchain, `tensorforge-opt`, and lit infrastructure are in place; 2/2 lit tests pass. Details and job table in `docs/stage0.md`.

Failures on the way: the first lit-tools build extracted only part of the LLVM source (fixed by extracting all of it); the first lit run used the deprecated external shell (fixed). The GitHub repository did not exist at session start; Nirak created it during the session.

Commits: see `git log` (`stage0:` prefix).

## Open questions

- CMake `ZLIB_LIBRARY` not found warning during configure (no effect so far).
