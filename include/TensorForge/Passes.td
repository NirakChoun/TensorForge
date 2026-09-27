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

def TForgeTileAndFuse : Pass<"tforge-tile-and-fuse", "::mlir::func::FuncOp"> {
  let summary = "Tile the last linalg op of each chain and fuse its producers";
  let description = [{
    For each tensor-semantics linalg op whose results feed no other linalg op
    (the root), tile its parallel loops with `tile-sizes` (and its reduction
    loop with `tile-k` if nonzero) into scf.for loops and fuse the producer
    chain (for example fill and matmul feeding an epilogue) into the loop body
    with upstream `scf::tileConsumerAndFuseProducersUsingSCF`.
  }];
  let options = [
    ListOption<"tileSizes", "tile-sizes", "int64_t",
               "Tile sizes for the parallel loops of the root, outermost first">,
    Option<"tileK", "tile-k", "int64_t", /*default=*/"0",
           "Tile size for the reduction loop of the root (0 = do not tile)">,
  ];
  let dependentDialects = [
    "::mlir::affine::AffineDialect",
    "::mlir::arith::ArithDialect",
    "::mlir::linalg::LinalgDialect",
    "::mlir::scf::SCFDialect",
    "::mlir::tensor::TensorDialect",
  ];
}

#endif // TENSORFORGE_PASSES
