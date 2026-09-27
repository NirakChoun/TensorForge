# E4: pipeline debugging and source locations

Both pipelines take a `print-after-each=1` option that prints the module to stderr after each named TensorForge stage, under a `// ----- tforge: after <stage> -----` header. With `--mlir-print-debuginfo`, every lowered op shows the `tforge` source location it came from, and TensorForge's own diagnostics point at the `tforge` op in the input file.

## Usage

```
tensorforge-opt in.mlir --tforge-gpu-pipeline="block-tile=128,64 thread-tile=8,4 tile-k=16 promote=1 vectorize=1 print-after-each=1" \
    --mlir-print-debuginfo -o out.mlir 2> stages.mlir
```

| Pipeline | Stages printed |
|---|---|
| `--tforge-cpu-pipeline` | `tforge-to-linalg`, `fusion-tiling-vectorization`, `bufferization`, `loops` |
| `--tforge-gpu-pipeline` | `tforge-to-linalg`, `gpu-tiling`, `bufferization`, `gpu-mapping`, `outlining` |

## Design

Upstream MLIR already has `--mlir-print-ir-after-all` and `--mlir-print-ir-after=<pass>`. They print after every pass of the pipeline (39 dumps for the vectorized CPU pipeline and 29 for the staged GPU pipeline on a fused kernel, including each `canonicalize`), or after every instance of one pass. `print-after-each` prints only at the stage boundaries that match the pipeline's structure. Upstream's options still work and are used in the lit tests.

TensorForge adds one pass, `tforge-print-ir{label=...}` (`lib/Transforms/PrintIR.cpp`), which prints the module with the global printing flags and changes nothing. When the option is set, `lib/Pipelines/Pipelines.cpp` inserts it at the stage boundaries. The GPU pipeline's existing `print-script=1` option prints the generated Transform-dialect scripts.

Source locations come from upstream: the `tforge` to Linalg conversion creates each op at the location of the `tforge` op it replaces, and upstream tiling, bufferization, and lowering keep those locations. The `tforge-gpu-tile` pass reports unsupported inputs (for example, a problem that is not padded to the tile sizes) on the offending op, so the error points at the `tforge.matmul` line in the source file.

## Tests

- `test/Pipelines/print-after-each.mlir` checks the stage headers and their order for both pipelines. For the GPU pipeline, it also checks that `linalg.matmul` carries the location of the `tforge.matmul` on line 25 of the test file.
- `test/Pipelines/gpu-staged.mlir` (NOTPADDED) checks that the staged-kernel error is reported at `file:line:col` of the `tforge.matmul`.
