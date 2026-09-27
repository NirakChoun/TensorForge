# Stage 2: canonicalization

## Question

Which algebraic simplifications of `tforge` are exact under IEEE-754 f32 semantics, and which need fast-math assumptions? `relu(relu(x)) -> relu(x)`, `x + (-0.0) -> x`, and constant folding are exact. `x + (+0.0) -> x` is not exact (when `x` is `-0.0` the original produces `+0.0`, the fold keeps `-0.0`), so TensorForge folds it only when `x` provably cannot be `-0.0`.

## Design

TensorForge implements the folds as op folders (`lib/Dialect/TForge/TForgeFolders.cpp`) run by upstream `--canonicalize`. Upstream MLIR supplies the greedy driver, dead-code elimination of unused `Pure` ops, operand reordering for the `Commutative` trait (constants move to the rhs of `add`), and `arith.constant` materialization of folded values.

| Pattern | Condition | Implemented in |
|---|---|---|
| `relu(relu(x)) -> relu(x)` | always | `ReluOp::fold` |
| `add(x, splat -0.0) -> x`, either operand order | always | `AddOp::fold` |
| `add(x, splat +0.0) -> x`, either operand order | only if `x` is a `relu` result | `AddOp::fold` |
| `bias_add(x, splat -0.0) -> x` | always | `BiasAddOp::fold` |
| `bias_add(x, splat +0.0) -> x` | only if `x` is a `relu` result | `BiasAddOp::fold` |
| constant folding of `add`, `relu`, `bias_add` | all operands constant | op folders |

`matmul` is not constant-folded; the brief scopes constant folding to elementwise ops.

## Legality

Notation: `maximum` is the IEEE-754-2019 operation that `arith.maximumf` implements. It returns NaN if either input is NaN and orders `-0.0 < +0.0`.

**`relu(relu(x)) -> relu(x)`.** Let `r = maximum(x, +0.0)`. If `x` is NaN, `r` is NaN and `maximum(NaN, +0.0)` is NaN. Otherwise `r` is `+0.0` or a positive number; it is never `-0.0`, because `maximum(-0.0, +0.0) = +0.0`. For such `r`, `maximum(r, +0.0) = r`. The fold is exact for every input, including NaN and both zeros, with no fast-math flags.

**`x + (-0.0) -> x`.** In round-to-nearest-even, `x + (-0.0) = x` for every finite or infinite `x`, including `(+0.0) + (-0.0) = +0.0` and `(-0.0) + (-0.0) = -0.0`. For NaN `x` the sum is a NaN; the fold returns the original NaN, which only differs in the NaN payload/quieting of a signaling NaN. Neither TensorForge nor the lowered code distinguishes NaN payloads, so this is treated as exact.

**`x + (+0.0) -> x` is not exact in general.** `(-0.0) + (+0.0) = +0.0` in round-to-nearest-even, so replacing the sum by `x` turns a `+0.0` result into `-0.0`. The two compare equal, but the bits differ, and they behave differently afterwards (for example `1/x`, `copysign`). LLVM refuses the same fold without the `nsz` flag. TensorForge applies it only when `x` is the result of `relu`, which never produces `-0.0` (argument above). The test `add_pos_zero_kept` checks that the general case is left alone.

**`bias_add`** adds one bias element to each input element, so the same two arguments apply per element.

**Constant folding.** Folders compute with `llvm::APFloat` in IEEE single precision: one `add` in round-to-nearest-even per element, and `llvm::maximum` for `relu`. These are the operations the lowered code performs (`arith.addf` becomes an LLVM `fadd`; `arith.maximumf` becomes `llvm.maximum`), so folded and run-time results are bit-identical except for NaN payloads. Two caveats:

- Denormals: the folder never flushes subnormals to zero. Code compiled with flush-to-zero (for example NVPTX `.ftz` modes, or x86 with FTZ/DAZ set in MXCSR) would flush them at run time. TensorForge's CPU and GPU pipelines do not enable flush-to-zero.
- Size: folding materializes the full result as a dense attribute. There is no size limit; very large constant tensors would increase compile time and memory.

## Setup

MLIR/LLVM 23.1.2, built and tested in a CPU Slurm allocation. Test: `test/Transforms/canonicalize.mlir` (10 cases; each function body is the "before" and its CHECK lines are the "after").

## Results

| Case | Before | After |
|---|---|---|
| `relu_relu` | `relu(relu(relu(x)))` and `relu(relu(x))` | one `relu(x)` used for both results |
| `add_neg_zero` | `x + splat(-0.0)`, `splat(-0.0) + x` | `x` |
| `add_pos_zero_kept` | `splat(+0.0) + x` | `x + splat(+0.0)` (reordered, not folded) |
| `add_pos_zero_after_relu` | `relu(y) + splat(+0.0)` | `relu(y)` |
| `add_mixed_zero_kept` | `x + [-0.0, +0.0]` | unchanged |
| `add_const` | `[1, 2] + [0.5, -3]`; `splat(1) + splat(2)` | `[1.5, -1]`; `splat(3)` |
| `relu_const` | `relu([-1, -0.0, NaN, 2.5, 0])` | `[0, 0, NaN, 2.5, 0]` |
| `bias_add_const` | `relu(bias_add([[1,2],[3,4]], [10,-20]))` | `[[11, 0], [13, 0]]` |
| `bias_add_neg_zero` | `bias_add(x, splat(-0.0))` | `x` |
| `matmul_not_folded` | constant `matmul`, unused `relu` | `matmul` kept, `relu` erased |

All 5 lit test files pass.

## Observations

- Because `add` is `Commutative`, the canonicalizer moves the constant to the rhs before folding, which is visible in `add_pos_zero_kept`.
- `relu` of `-0.0` folds to `+0.0` and `relu` of NaN stays NaN (`0x7FC00000`), matching `arith.maximumf`.

## Interpretation

TODO(Nirak)

## Open questions

- The `+0.0` fold recognizes only a direct `relu` producer. A dataflow analysis ("never `-0.0`") would cover more cases, for example the output of `add(relu(a), relu(b))`.
