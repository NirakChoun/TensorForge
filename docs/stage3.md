# Stage 3: lowering to upstream dialects

## Question

Can every `tforge` op be expressed in upstream Linalg/Tensor/Arith so that all later transformations (fusion, tiling, vectorization, GPU mapping) come from upstream MLIR? Yes: `--convert-tforge-to-linalg` lowers all four ops, and the conversion fails if any `tforge` op remains.

## Design

TensorForge: `lib/Conversion/TForgeToLinalg.cpp`, one `OpConversionPattern` per op, driven by upstream `applyPartialConversion` with the `tforge` dialect marked illegal.

| `tforge` op | Upstream form |
|---|---|
| `matmul` | `linalg.matmul` with init `linalg.fill(+0.0, tensor.empty)` |
| `add` | `linalg.generic`, identity maps, all `parallel`, body `arith.addf` |
| `relu` | `linalg.generic`, identity maps, body `arith.maximumf(x, +0.0)` |
| `bias_add` | `linalg.generic`, maps `(d0..dn) -> (d0..dn)` and `(d0..dn) -> (dn)`, body `arith.addf` |

Choices:

- Each op writes a fresh `tensor.empty`. This keeps the lowering one-to-one; buffer reuse is the job of bufferization and of Stage 5's fusion.
- Elementwise ops use `linalg.generic` rather than named ops (`linalg.add`, `linalg.max`) because upstream elementwise fusion works on generics and because bias broadcasting is expressed directly in the indexing map.
- The zero is `+0.0`. As the matmul initial value it gives `0 + first product`, and as the relu threshold it gives `relu(-0.0) = +0.0` (see `docs/dialect.md`).

The lowering preserves the Stage 1 semantics exactly: each `tforge` scalar operation maps to the same `arith` operation. Execution is tested against NumPy in Stage 4.

## Setup

MLIR/LLVM 23.1.2. Test: `test/Conversion/tforge-to-linalg.mlir`, run with `FileCheck --implicit-check-not=tforge.` so any leftover `tforge` op fails the test.

## Results

| Case | Checked |
|---|---|
| dense layer 67x33 by 33x17 + bias + relu | full structure: fill, matmul, bias generic with `(d0, d1) -> (d1)` map, relu generic with `maximumf` |
| rank 3 add and bias_add; rank 0 add | indexing maps and iterator types for ranks 3 and 0 |
| non-`tforge` ops | passed through unchanged |

6/6 lit test files pass.

## Observations

- Upstream `linalg.generic` accepts rank-0 tensors (`affine_map<() -> ()>`, no iterators), so scalar `tforge.add` needs no special case.

## Interpretation

TODO(Nirak)

## Open questions

None.
