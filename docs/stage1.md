# Stage 1: the `tforge` dialect

## Question

Can a four-op dialect express a dense layer while rejecting every malformed program with a diagnostic that names the exact problem? Yes: `add`, `relu`, `matmul`, and `bias_add` are defined in ODS with C++ verifiers, and each of 18 malformed cases produces its specific message.

## Design

TensorForge:

- ODS definitions for the dialect and four ops (`TForgeOps.td`), with custom assembly formats that spell out every operand and result type.
- C++ verifiers (`TForgeOps.cpp`) for tensor kind, static shape, `f32` element type, and per-op shape rules. Operands are declared `AnyTensor` so shape and element-type errors come from these verifiers, which report both shapes involved (for example, both K dimensions of a matmul), instead of from generic ODS type-constraint messages.
- Semantics in `docs/dialect.md`, including NaN and signed-zero behavior of `relu`.

Upstream MLIR: TableGen op generation (`add_mlir_dialect`), the parser/printer, `-verify-diagnostics`, and `-split-input-file`.

## Setup

MLIR/LLVM 23.1.2, GCC 15.3, built and tested in a CPU Slurm allocation (8 cores). Tests: `test/Dialect/TForge/ops.mlir`, `test/Dialect/TForge/invalid.mlir`.

## Results

| Test | Content | Result |
|---|---|---|
| `ops.mlir` | dense layer; ranks 0, 1, 2, 3; odd shapes (17x1 by 1x33, 3x5x7); custom and generic round trip | pass |
| `invalid.mlir` | 18 rejected cases: non-tensor, unranked, dynamic, f16/i32/f64 elements, add shape and broadcast, result-shape mismatches for each op, matmul rank and K mismatch, bias rank/length/scalar input | pass |
| Stage 0 tests | round trip, registration (now includes `tforge`) | pass |

## Observations

- In MLIR 23 the ODS message for `AnyTensor` reads "tensor of any non-token type values".
- `-verify-diagnostics` also fails on unexpected diagnostics, so each case produces exactly one error.

## Interpretation

TODO(Nirak)

## Open questions

None.
