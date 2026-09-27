# The `tforge` dialect

`tforge` is TensorForge's input dialect: four value-semantic ops on ranked, statically shaped `f32` tensors, enough to express a dense layer `relu(x @ W + b)`. It is defined in `include/TensorForge/Dialect/TForge/TForgeOps.td`; verifiers are in `lib/Dialect/TForge/TForgeOps.cpp`.

## Type rules (all ops)

Every operand and result must be:

1. a ranked tensor (not unranked `tensor<*xf32>`),
2. statically shaped (no `?` dimensions),
3. of element type `f32`.

The verifier checks these in that order and names the offending value (`lhs`, `rhs`, `input`, `bias`, `result`). Result types are written explicitly and must match the shape rules below; there is no implicit broadcasting.

All ops are `Pure` (no side effects), so unused results are erased by standard dead-code elimination.

## Ops

| Op | Operands | Result | Semantics |
|---|---|---|---|
| `tforge.add` | `lhs : S`, `rhs : S` | `S` | `result[i] = lhs[i] + rhs[i]`, IEEE-754 f32 addition, round to nearest-even. Any rank, including 0. Commutative. |
| `tforge.relu` | `input : S` | `S` | `result[i] = maximum(input[i], +0.0)` with IEEE-754-2019 `maximum` (the semantics of `arith.maximumf`). Any rank. |
| `tforge.matmul` | `lhs : MxK`, `rhs : KxN` | `MxN` | `result[m, n] = sum_k lhs[m, k] * rhs[k, n]`. Rank 2 only. Summation order unspecified. |
| `tforge.bias_add` | `input : [..., N]`, `bias : N` | shape of `input` | `result[..., j] = input[..., j] + bias[j]`. `input` rank >= 1, `bias` rank 1. |

### Floating-point details

- `relu` propagates NaN (`relu(NaN) = NaN`) and maps `-0.0` to `+0.0`, because `maximum` orders `-0.0 < +0.0`. The same rule means `relu` never returns `-0.0`, which Stage 2's `add` folding relies on.
- `matmul` does not fix the order of the `K` additions. Tiling and vectorization reassociate the sum, so results can differ from a sequential sum in the last bits; `docs/numerics.md` measures this.
- `add` and `bias_add` are single IEEE additions per element, so any correct lowering is bit-exact against NumPy `float32`.

## Syntax

```mlir
%mm = tforge.matmul %x, %w : tensor<64x32xf32>, tensor<32x16xf32> -> tensor<64x16xf32>
%ba = tforge.bias_add %mm, %b : tensor<64x16xf32>, tensor<16xf32> -> tensor<64x16xf32>
%r  = tforge.relu %ba : tensor<64x16xf32> -> tensor<64x16xf32>
%s  = tforge.add %r, %r : tensor<64x16xf32>, tensor<64x16xf32> -> tensor<64x16xf32>
```

## Diagnostics

Examples of the verifier messages (full list in `test/Dialect/TForge/invalid.mlir`):

```
'tforge.matmul' op contracting dimensions do not match: lhs is 64x32 (K = 32), rhs is 16x16 (K = 16)
'tforge.matmul' op result shape must be 64x16 (M x N), but got 16x64
'tforge.add' op operand shapes must match (no implicit broadcasting): lhs is 4x8, rhs is 8
'tforge.bias_add' op bias length 4 does not match the last dimension of input 4x8 (8)
'tforge.relu' op input must have a static shape, but got 'tensor<?x4xf32>'
```
