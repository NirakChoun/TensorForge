//===- TForgeOps.td - TensorForge tensor dialect -----------*- tablegen -*-===//
//
// The tforge dialect: a small, value-semantic tensor dialect for dense f32
// neural-network layers. Every operand and result is a ranked, statically
// shaped tensor of f32. There is no implicit broadcasting; bias_add is the one
// op whose operands differ in shape, and its broadcast is part of its
// definition. See docs/dialect.md for the exact semantics.
//
//===----------------------------------------------------------------------===//

#ifndef TFORGE_OPS
#define TFORGE_OPS

include "mlir/IR/OpBase.td"
include "mlir/Interfaces/SideEffectInterfaces.td"

def TForge_Dialect : Dialect {
  let name = "tforge";
  let cppNamespace = "::mlir::tforge";
  let summary = "TensorForge tensor dialect";
  let description = [{
    High-level tensor operations (add, relu, matmul, bias_add) on ranked,
    statically shaped f32 tensors. The dialect is lowered to upstream
    Linalg/Tensor/Arith by --convert-tforge-to-linalg.
  }];
  // Folded constants are materialized as arith.constant.
  let dependentDialects = ["::mlir::arith::ArithDialect"];
  let hasConstantMaterializer = 1;
}

class TForge_Op<string mnemonic, list<Trait> traits = []>
    : Op<TForge_Dialect, mnemonic, traits>;

// Operands accept any tensor so that the C++ verifiers, not ODS type
// constraints, report rank/shape/element-type errors with specific messages.

def TForge_AddOp : TForge_Op<"add", [Pure, Commutative]> {
  let summary = "elementwise addition of two same-shaped tensors";
  let description = [{
    `result[i] = lhs[i] + rhs[i]` for every index `i`, with IEEE-754 f32
    addition rounded to nearest-even. `lhs`, `rhs`, and `result` must have the
    same shape; there is no broadcasting.

    ```mlir
    %r = tforge.add %a, %b : tensor<4x8xf32>, tensor<4x8xf32> -> tensor<4x8xf32>
    ```
  }];
  let arguments = (ins AnyTensor:$lhs, AnyTensor:$rhs);
  let results = (outs AnyTensor:$result);
  let assemblyFormat = [{
    $lhs `,` $rhs attr-dict `:` type($lhs) `,` type($rhs) `->` type($result)
  }];
  let hasVerifier = 1;
  let hasFolder = 1;
}

def TForge_ReluOp : TForge_Op<"relu", [Pure]> {
  let summary = "elementwise rectified linear unit";
  let description = [{
    `result[i] = maximum(input[i], +0.0)` using the IEEE-754-2019 `maximum`
    operation (the semantics of `arith.maximumf`): NaN inputs produce NaN, and
    `-0.0` produces `+0.0` because `-0.0 < +0.0` for this operation.

    ```mlir
    %r = tforge.relu %x : tensor<4x8xf32> -> tensor<4x8xf32>
    ```
  }];
  let arguments = (ins AnyTensor:$input);
  let results = (outs AnyTensor:$result);
  let assemblyFormat = "$input attr-dict `:` type($input) `->` type($result)";
  let hasVerifier = 1;
  let hasFolder = 1;
}

def TForge_MatmulOp : TForge_Op<"matmul", [Pure]> {
  let summary = "two-dimensional matrix multiplication";
  let description = [{
    `result[m, n] = sum over k of lhs[m, k] * rhs[k, n]` for `lhs : MxK`,
    `rhs : KxN`, `result : MxN`. The summation order is unspecified; lowerings
    and tilings may reassociate it (see docs/numerics.md).

    ```mlir
    %c = tforge.matmul %a, %b : tensor<64x32xf32>, tensor<32x16xf32> -> tensor<64x16xf32>
    ```
  }];
  let arguments = (ins AnyTensor:$lhs, AnyTensor:$rhs);
  let results = (outs AnyTensor:$result);
  let assemblyFormat = [{
    $lhs `,` $rhs attr-dict `:` type($lhs) `,` type($rhs) `->` type($result)
  }];
  let hasVerifier = 1;
}

def TForge_BiasAddOp : TForge_Op<"bias_add", [Pure]> {
  let summary = "add a 1-D bias along the last dimension";
  let description = [{
    For `input` of rank R >= 1 with last dimension N and `bias : N`,
    `result[i, j] = input[i, j] + bias[j]`, where `j` indexes the last
    dimension and `i` stands for all leading indices. `result` has the shape
    of `input`.

    ```mlir
    %y = tforge.bias_add %x, %b : tensor<64x16xf32>, tensor<16xf32> -> tensor<64x16xf32>
    ```
  }];
  let arguments = (ins AnyTensor:$input, AnyTensor:$bias);
  let results = (outs AnyTensor:$result);
  let assemblyFormat = [{
    $input `,` $bias attr-dict `:` type($input) `,` type($bias) `->` type($result)
  }];
  let hasVerifier = 1;
  let hasFolder = 1;
}

#endif // TFORGE_OPS
