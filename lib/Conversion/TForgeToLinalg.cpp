//===- TForgeToLinalg.cpp - lower tforge to linalg/tensor/arith -----------===//

#include "TensorForge/Conversion/TForgeToLinalg.h"
#include "TensorForge/Dialect/TForge/TForgeDialect.h"
#include "TensorForge/Dialect/TForge/TForgeOps.h"
#include "TensorForge/Passes.h"

#include "mlir/Dialect/Arith/IR/Arith.h"
#include "mlir/Dialect/Linalg/IR/Linalg.h"
#include "mlir/Dialect/Tensor/IR/Tensor.h"
#include "mlir/IR/AffineMap.h"
#include "mlir/Transforms/DialectConversion.h"

namespace mlir {
namespace tforge {
#define GEN_PASS_DEF_CONVERTTFORGETOLINALG
#include "TensorForge/Passes.h.inc"
} // namespace tforge
} // namespace mlir

using namespace mlir;
using namespace mlir::tforge;

namespace {

Value createEmpty(OpBuilder &b, Location loc, RankedTensorType type) {
  return tensor::EmptyOp::create(b, loc, type.getShape(),
                                 type.getElementType());
}

Value createZero(OpBuilder &b, Location loc, Type elementType) {
  // +0.0, not -0.0: this is both the matmul accumulator start value and the
  // relu threshold, and relu's -0.0 -> +0.0 behavior depends on it.
  return arith::ConstantOp::create(b, loc, b.getFloatAttr(elementType, 0.0));
}

/// Builds an all-parallel linalg.generic writing a fresh tensor.empty of
/// `type`. `inputMaps` index the inputs; the output uses the identity map.
Value buildElementwise(
    OpBuilder &b, Location loc, RankedTensorType type, ValueRange inputs,
    ArrayRef<AffineMap> inputMaps,
    function_ref<Value(OpBuilder &, Location, ValueRange)> scalarFn) {
  unsigned rank = type.getRank();
  Value init = createEmpty(b, loc, type);
  SmallVector<AffineMap> maps(inputMaps.begin(), inputMaps.end());
  maps.push_back(b.getMultiDimIdentityMap(rank));
  SmallVector<utils::IteratorType> iterators(rank,
                                             utils::IteratorType::parallel);
  auto generic = linalg::GenericOp::create(
      b, loc, TypeRange{type}, inputs, ValueRange{init}, maps, iterators,
      [&](OpBuilder &nb, Location nloc, ValueRange args) {
        linalg::YieldOp::create(nb, nloc, scalarFn(nb, nloc, args));
      });
  return generic->getResult(0);
}

struct MatmulLowering : OpConversionPattern<MatmulOp> {
  using OpConversionPattern::OpConversionPattern;
  LogicalResult
  matchAndRewrite(MatmulOp op, OpAdaptor adaptor,
                  ConversionPatternRewriter &rewriter) const override {
    Location loc = op.getLoc();
    auto type = cast<RankedTensorType>(op.getResult().getType());
    Value zero = createZero(rewriter, loc, type.getElementType());
    Value init = createEmpty(rewriter, loc, type);
    Value filled =
        linalg::FillOp::create(rewriter, loc, zero, init)->getResult(0);
    auto matmul = linalg::MatmulOp::create(
        rewriter, loc, TypeRange{type},
        ValueRange{adaptor.getLhs(), adaptor.getRhs()}, ValueRange{filled});
    rewriter.replaceOp(op, matmul->getResults());
    return success();
  }
};

struct AddLowering : OpConversionPattern<AddOp> {
  using OpConversionPattern::OpConversionPattern;
  LogicalResult
  matchAndRewrite(AddOp op, OpAdaptor adaptor,
                  ConversionPatternRewriter &rewriter) const override {
    auto type = cast<RankedTensorType>(op.getResult().getType());
    AffineMap id = rewriter.getMultiDimIdentityMap(type.getRank());
    Value result = buildElementwise(
        rewriter, op.getLoc(), type,
        ValueRange{adaptor.getLhs(), adaptor.getRhs()}, {id, id},
        [](OpBuilder &b, Location loc, ValueRange args) -> Value {
          return arith::AddFOp::create(b, loc, args[0], args[1]);
        });
    rewriter.replaceOp(op, result);
    return success();
  }
};

struct ReluLowering : OpConversionPattern<ReluOp> {
  using OpConversionPattern::OpConversionPattern;
  LogicalResult
  matchAndRewrite(ReluOp op, OpAdaptor adaptor,
                  ConversionPatternRewriter &rewriter) const override {
    Location loc = op.getLoc();
    auto type = cast<RankedTensorType>(op.getResult().getType());
    Value zero = createZero(rewriter, loc, type.getElementType());
    AffineMap id = rewriter.getMultiDimIdentityMap(type.getRank());
    Value result = buildElementwise(
        rewriter, loc, type, ValueRange{adaptor.getInput()}, {id},
        [&](OpBuilder &b, Location l, ValueRange args) -> Value {
          return arith::MaximumFOp::create(b, l, args[0], zero);
        });
    rewriter.replaceOp(op, result);
    return success();
  }
};

struct BiasAddLowering : OpConversionPattern<BiasAddOp> {
  using OpConversionPattern::OpConversionPattern;
  LogicalResult
  matchAndRewrite(BiasAddOp op, OpAdaptor adaptor,
                  ConversionPatternRewriter &rewriter) const override {
    auto type = cast<RankedTensorType>(op.getResult().getType());
    unsigned rank = type.getRank();
    MLIRContext *ctx = rewriter.getContext();
    AffineMap id = rewriter.getMultiDimIdentityMap(rank);
    AffineMap lastDim =
        AffineMap::get(rank, 0, {getAffineDimExpr(rank - 1, ctx)}, ctx);
    Value result = buildElementwise(
        rewriter, op.getLoc(), type,
        ValueRange{adaptor.getInput(), adaptor.getBias()}, {id, lastDim},
        [](OpBuilder &b, Location loc, ValueRange args) -> Value {
          return arith::AddFOp::create(b, loc, args[0], args[1]);
        });
    rewriter.replaceOp(op, result);
    return success();
  }
};

struct ConvertTForgeToLinalgPass
    : tforge::impl::ConvertTForgeToLinalgBase<ConvertTForgeToLinalgPass> {
  void runOnOperation() override {
    MLIRContext *ctx = &getContext();
    ConversionTarget target(*ctx);
    target.addIllegalDialect<TForgeDialect>();
    target.addLegalDialect<arith::ArithDialect, linalg::LinalgDialect,
                           tensor::TensorDialect>();
    target.markUnknownOpDynamicallyLegal([](Operation *) { return true; });

    RewritePatternSet patterns(ctx);
    populateTForgeToLinalgPatterns(patterns);
    if (failed(applyPartialConversion(getOperation(), target,
                                      std::move(patterns))))
      signalPassFailure();
  }
};

} // namespace

void mlir::tforge::populateTForgeToLinalgPatterns(RewritePatternSet &patterns) {
  patterns.add<MatmulLowering, AddLowering, ReluLowering, BiasAddLowering>(
      patterns.getContext());
}
