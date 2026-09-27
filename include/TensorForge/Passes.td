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
    loops of fused contractions with `tile-k` if nonzero) into scf.for loops
    and fuse the producer
    chain (for example fill and matmul feeding an epilogue) into the loop body
    with upstream `scf::tileConsumerAndFuseProducersUsingSCF`.
  }];
  let options = [
    ListOption<"tileSizes", "tile-sizes", "int64_t",
               "Tile sizes for the parallel loops of the root, outermost first">,
    Option<"tileK", "tile-k", "int64_t", /*default=*/"0",
           "Tile the reduction loop of each tiled contraction (0 = do not tile)">,
    Option<"peel", "peel", "bool", /*default=*/"false",
           "Peel the created loops so full tiles have static shapes">,
  ];
  let dependentDialects = [
    "::mlir::affine::AffineDialect",
    "::mlir::arith::ArithDialect",
    "::mlir::linalg::LinalgDialect",
    "::mlir::scf::SCFDialect",
    "::mlir::tensor::TensorDialect",
  ];
}

def TForgeVectorize : Pass<"tforge-vectorize", "::mlir::func::FuncOp"> {
  let summary = "Vectorize statically shaped register tiles with upstream linalg::vectorize";
  let description = [{
    Vectorizes every tensor-semantics linalg op with a static shape whose
    iteration space has at most `max-iterations` points. Contractions are
    emitted directly as vector.contract. Dynamically shaped ops
    (peeled remainders) are left for convert-linalg-to-loops.
  }];
  let options = [
    Option<"maxIterations", "max-iterations", "int64_t", /*default=*/"4096",
           "Largest iteration space to vectorize">,
  ];
  let dependentDialects = [
    "::mlir::arith::ArithDialect",
    "::mlir::tensor::TensorDialect",
    "::mlir::vector::VectorDialect",
  ];
}

#endif // TENSORFORGE_PASSES
