//===- Passes.td - TensorForge passes --------------------*- tablegen -*-===//

#ifndef TENSORFORGE_PASSES
#define TENSORFORGE_PASSES

include "mlir/Pass/PassBase.td"

def ConvertTForgeToLinalg : Pass<"convert-tforge-to-linalg", "ModuleOp"> {
  let summary = "Lower tforge ops to upstream linalg, tensor, and arith";
  let description = [{
    Dialect conversion with every tforge op illegal, so the pass fails if any
    tforge op cannot be lowered.

    - `tforge.matmul` becomes `linalg.matmul` whose init is a
      `linalg.fill` of +0.0 into a `tensor.empty`.
    - `tforge.add`, `tforge.relu`, `tforge.bias_add` become `linalg.generic`
      ops with all-parallel iterators and a `tensor.empty` init. relu uses
      `arith.maximumf` against +0.0; bias_add indexes the bias with the last
      loop dimension.
  }];
  let dependentDialects = [
    "::mlir::arith::ArithDialect",
    "::mlir::linalg::LinalgDialect",
    "::mlir::tensor::TensorDialect",
  ];
}

#endif // TENSORFORGE_PASSES
