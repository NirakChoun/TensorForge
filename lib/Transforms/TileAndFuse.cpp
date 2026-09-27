//===- TileAndFuse.cpp - tile matmul epilogues and fuse producers ---------===//
//
// TensorForge policy on top of upstream MLIR: choose the root of each
// producer/consumer chain, choose which loops to tile, and call upstream
// scf::tileConsumerAndFuseProducersUsingSCF. For relu(matmul + bias) after
// upstream elementwise fusion, the root is the epilogue linalg.generic; the
// matmul and its zero fill are fused into the tile loop, so each (tm x tn)
// tile of the matmul result is produced and consumed while it is in cache and
// is never materialized at full size.
//
// The pass is applied twice by the CPU pipeline: once for cache tiles and once
// for register tiles (with reduction tiling of the fused matmul and loop
// peeling, so full register tiles have static shapes and can be vectorized).
//
//===----------------------------------------------------------------------===//

#include "TensorForge/Passes.h"

#include "mlir/Dialect/Affine/IR/AffineOps.h"
#include "mlir/Dialect/Arith/IR/Arith.h"
#include "mlir/Dialect/Func/IR/FuncOps.h"
#include "mlir/Dialect/Linalg/IR/Linalg.h"
#include "mlir/Dialect/SCF/IR/SCF.h"
#include "mlir/Dialect/SCF/Transforms/TileUsingInterface.h"
#include "mlir/Dialect/SCF/Transforms/Transforms.h"
#include "mlir/Dialect/Tensor/IR/Tensor.h"
#include "mlir/Dialect/Tensor/Transforms/Transforms.h"
#include "mlir/IR/IRMapping.h"
#include "mlir/IR/PatternMatch.h"
#include "mlir/Interfaces/TilingInterface.h"
#include "mlir/Transforms/GreedyPatternRewriteDriver.h"

namespace mlir {
namespace tforge {
#define GEN_PASS_DEF_TFORGETILEANDFUSE
#include "TensorForge/Passes.h.inc"
} // namespace tforge
} // namespace mlir

using namespace mlir;

namespace {

/// A root is a tensor-semantics linalg op whose results feed no other linalg
/// op: the last op of a chain. Tiling it and fusing producers covers the chain.
SmallVector<TilingInterface> findRoots(func::FuncOp func) {
  SmallVector<TilingInterface> roots;
  func.walk([&](linalg::LinalgOp op) {
    if (op->getNumResults() == 0 || !op.hasPureTensorSemantics())
      return;
    if (llvm::any_of(op->getUsers(),
                     [](Operation *u) { return isa<linalg::LinalgOp>(u); }))
      return;
    // Zero-rank ops have no loops to tile.
    if (op.getNumLoops() == 0)
      return;
    if (auto t = dyn_cast<TilingInterface>(op.getOperation()))
      roots.push_back(t);
  });
  return roots;
}

/// Rewrites an elementwise epilogue so that it updates its producer's result
/// in place:
///
///   %p = linalg.matmul ... outs(%acc)
///   %r = linalg.generic ins(%p, %bias) outs(%init) { use(%p_elem) }
/// becomes
///   %r = linalg.generic ins(%bias) outs(%p) { use(%out_elem) }
///
/// Legal when the generic is all-parallel, never reads its current init, and
/// reads %p with the same (identity) map it writes: each element is read then
/// overwritten at the same index. %p must have no other use. After this, the
/// chain empty -> fill -> matmul -> epilogue -> insert_slice is a pure
/// destination chain, which upstream -eliminate-empty-tensors turns into
/// in-place updates of the output tile (no temporary buffer).
struct EpilogueIntoProducerInit : OpRewritePattern<linalg::GenericOp> {
  using OpRewritePattern::OpRewritePattern;

  LogicalResult matchAndRewrite(linalg::GenericOp op,
                                PatternRewriter &rewriter) const override {
    if (op.getNumDpsInits() != 1 || !op.hasPureTensorSemantics() ||
        op.getNumParallelLoops() != op.getNumLoops())
      return failure();
    OpOperand *init = op.getDpsInitOperand(0);
    if (op.payloadUsesValueFromOperand(init))
      return failure();
    AffineMap outMap = op.getMatchingIndexingMap(init);
    if (!outMap.isIdentity())
      return failure();

    for (OpOperand *in : op.getDpsInputOperands()) {
      Value v = in->get();
      if (v.getType() != init->get().getType() ||
          op.getMatchingIndexingMap(in) != outMap || !v.hasOneUse() ||
          !v.getDefiningOp<linalg::LinalgOp>())
        continue;

      SmallVector<Value> newIns;
      SmallVector<AffineMap> maps;
      SmallVector<OpOperand *> kept;
      for (OpOperand *o : op.getDpsInputOperands()) {
        if (o == in)
          continue;
        newIns.push_back(o->get());
        maps.push_back(op.getMatchingIndexingMap(o));
        kept.push_back(o);
      }
      maps.push_back(outMap);

      Block &oldBody = op.getRegion().front();
      auto newOp = linalg::GenericOp::create(
          rewriter, op.getLoc(), op.getResultTypes(), newIns, ValueRange{v},
          maps, op.getIteratorTypesArray(),
          [&](OpBuilder &b, Location, ValueRange args) {
            IRMapping map;
            for (auto [i, o] : llvm::enumerate(kept))
              map.map(oldBody.getArgument(o->getOperandNumber()), args[i]);
            Value outArg = args.back();
            map.map(oldBody.getArgument(in->getOperandNumber()), outArg);
            map.map(oldBody.getArgument(init->getOperandNumber()), outArg);
            for (Operation &o : oldBody)
              b.clone(o, map);
          });
      rewriter.replaceOp(op, newOp->getResults());
      return success();
    }
    return failure();
  }
};

struct TileAndFusePass
    : tforge::impl::TForgeTileAndFuseBase<TileAndFusePass> {
  using Base::Base;

  void runOnOperation() override {
    if (tileSizes.empty())
      return;
    func::FuncOp func = getOperation();
    MLIRContext *ctx = &getContext();
    IRRewriter rewriter(ctx);
    // Loops created by this pass, outermost first within each tiling.
    SmallVector<scf::ForOp> created;

    for (TilingInterface root : findRoots(func)) {
      // Parallel loops take the requested sizes in order. Reduction loops are
      // not tiled here; tile-k applies to the fused contraction below.
      SmallVector<OpFoldResult> sizes;
      unsigned next = 0;
      for (utils::IteratorType it : root.getLoopIteratorTypes()) {
        int64_t s = 0;
        if (it == utils::IteratorType::parallel && next < tileSizes.size())
          s = tileSizes[next++];
        sizes.push_back(rewriter.getIndexAttr(s));
      }

      scf::SCFTilingOptions tilingOptions;
      tilingOptions.setTileSizes(sizes);
      tilingOptions.setLoopType(scf::SCFTilingOptions::LoopType::ForOp);
      scf::SCFTileAndFuseOptions options;
      options.setTilingOptions(tilingOptions);

      rewriter.setInsertionPoint(root);
      FailureOr<scf::SCFTileAndFuseResult> result =
          scf::tileConsumerAndFuseProducersUsingSCF(rewriter, root, options);
      if (failed(result)) {
        root->emitError("tforge-tile-and-fuse: tiling failed");
        return signalPassFailure();
      }
      for (auto [orig, repl] : result->replacements)
        rewriter.replaceAllUsesWith(orig, repl);
      for (LoopLikeOpInterface l : result->loops)
        if (auto f = dyn_cast<scf::ForOp>(l.getOperation()))
          created.push_back(f);

      if (tileK > 0) {
        for (Operation *op : result->tiledAndFusedOps) {
          auto linalgOp = dyn_cast<linalg::LinalgOp>(op);
          if (!linalgOp || linalgOp.getNumReductionLoops() == 0)
            continue;
          if (failed(tileReduction(rewriter, cast<TilingInterface>(op),
                                   created)))
            return signalPassFailure();
        }
      }
    }

    // Peel innermost loops first so the full-tile body of every loop has
    // static trip-count-independent tile sizes. Peeling fails (and is skipped)
    // when a loop already divides evenly.
    if (peel) {
      for (scf::ForOp loop : llvm::reverse(created)) {
        scf::ForOp partial;
        (void)scf::peelForLoopAndSimplifyBounds(rewriter, loop, partial);
      }
    }

    RewritePatternSet patterns(ctx);
    patterns.add<EpilogueIntoProducerInit>(ctx);
    // extract_slice(tensor.empty) -> tensor.empty(tile): the fused fill then
    // starts from a tile-sized empty that -eliminate-empty-tensors can replace
    // with the output tile.
    tensor::populateFoldTensorEmptyPatterns(patterns);
    if (failed(applyPatternsGreedily(func, std::move(patterns))))
      return signalPassFailure();
  }

  /// Tiles the reduction loops of `op` by tile-k with an scf.for that carries
  /// the accumulator (matmul accumulates into its init, so this is exact
  /// reordering of the K sum only at tile granularity: see docs/numerics.md).
  LogicalResult tileReduction(IRRewriter &rewriter, TilingInterface op,
                              SmallVectorImpl<scf::ForOp> &created) {
    SmallVector<OpFoldResult> sizes;
    for (utils::IteratorType it : op.getLoopIteratorTypes())
      sizes.push_back(rewriter.getIndexAttr(
          it == utils::IteratorType::reduction ? int64_t(tileK) : 0));
    scf::SCFTilingOptions o;
    o.setTileSizes(sizes);
    o.setLoopType(scf::SCFTilingOptions::LoopType::ForOp);
    rewriter.setInsertionPoint(op);
    FailureOr<scf::SCFTilingResult> r = scf::tileUsingSCF(rewriter, op, o);
    if (failed(r))
      return op->emitError("tforge-tile-and-fuse: reduction tiling failed");
    rewriter.replaceOp(op, r->replacements);
    for (LoopLikeOpInterface l : r->loops)
      if (auto f = dyn_cast<scf::ForOp>(l.getOperation()))
        created.push_back(f);
    return success();
  }
};

} // namespace
