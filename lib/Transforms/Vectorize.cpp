//===- Vectorize.cpp - vectorize static tiles, hoist accumulators --------===//
//
// tforge-vectorize: calls upstream linalg::vectorize on every tensor-semantics
// linalg op whose shape is static and whose iteration space is small enough to
// be a register tile. Ops with dynamic shapes (peeled remainder tiles) are left
// for convert-linalg-to-loops, so edge tiles run as scalar code.
//
// Matmul tiles are vectorized directly to vector.contract (upstream option
// createNamedContraction), which the pipeline lowers to outer products and
// vector.fma. The accumulator of the K loop is then hoisted out of the loop by
// upstream -loop-invariant-subset-hoisting on tensors.
//
//===----------------------------------------------------------------------===//

#include "TensorForge/Passes.h"

#include "mlir/Dialect/Affine/IR/AffineOps.h"
#include "mlir/Dialect/Arith/IR/Arith.h"
#include "mlir/Dialect/Func/IR/FuncOps.h"
#include "mlir/Dialect/Linalg/IR/Linalg.h"
#include "mlir/Dialect/Linalg/Transforms/Transforms.h"
#include "mlir/Dialect/MemRef/IR/MemRef.h"
#include "mlir/Dialect/Tensor/IR/Tensor.h"
#include "mlir/Dialect/Vector/IR/VectorOps.h"
#include "mlir/Dialect/Vector/Transforms/VectorRewritePatterns.h"
#include "mlir/Transforms/GreedyPatternRewriteDriver.h"
#include "mlir/IR/PatternMatch.h"

namespace mlir {
namespace tforge {
#define GEN_PASS_DEF_TFORGEVECTORIZE
#include "TensorForge/Passes.h.inc"
} // namespace tforge
} // namespace mlir

using namespace mlir;

namespace {

struct VectorizePass : tforge::impl::TForgeVectorizeBase<VectorizePass> {
  using Base::Base;

  void runOnOperation() override {
    SmallVector<linalg::LinalgOp> candidates;
    getOperation().walk([&](linalg::LinalgOp op) {
      if (!op.hasPureTensorSemantics() || op.hasDynamicShape() ||
          op.getNumLoops() == 0)
        return;
      int64_t iterations = 1;
      for (int64_t r : op.getStaticLoopRanges())
        iterations *= r;
      // Whole un-tiled ops would become huge vectors; only register tiles
      // are vectorized.
      if (iterations > maxIterations)
        return;
      candidates.push_back(op);
    });

    IRRewriter rewriter(&getContext());
    for (linalg::LinalgOp op : candidates) {
      if (failed(linalg::vectorizeOpPrecondition(op)))
        continue;
      rewriter.setInsertionPoint(op);
      FailureOr<linalg::VectorizationResult> result = linalg::vectorize(
          rewriter, op, /*inputVectorSizes=*/{}, /*inputScalableVecDims=*/{},
          /*vectorizeNDExtract=*/false, /*flatten1DDepthwiseConv=*/false,
          /*assumeDynamicDimsMatchVecSizes=*/false,
          /*createNamedContraction=*/true);
      if (failed(result))
        continue;
      rewriter.replaceOp(op, result->replacements);
    }

    // The vectorizer emits mulf + multi_reduction for a matmul tile; turn it
    // into vector.contract so the contract lowering (outer products with
    // vector.fma) applies.
    RewritePatternSet patterns(&getContext());
    vector::populateVectorReductionToContractPatterns(patterns);
    if (failed(applyPatternsGreedily(getOperation(), std::move(patterns))))
      return signalPassFailure();
  }
};

} // namespace
