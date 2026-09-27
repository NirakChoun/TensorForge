//===- TForgeFolders.cpp - tforge folding and canonicalization -----------===//
//
// Folds run under --canonicalize. Each one is exact under IEEE-754 f32
// semantics (round to nearest-even, signed zeros, NaN propagation); the
// legality argument for each is in docs/stage2.md.
//
//===----------------------------------------------------------------------===//

#include "TensorForge/Dialect/TForge/TForgeOps.h"

#include "mlir/IR/BuiltinAttributes.h"
#include "llvm/ADT/APFloat.h"

using namespace mlir;
using namespace mlir::tforge;

using llvm::APFloat;

static APFloat addF32(const APFloat &a, const APFloat &b) {
  APFloat r(a);
  // The lowered code performs one f32 add in the default rounding mode.
  r.add(b, llvm::RoundingMode::NearestTiesToEven);
  return r;
}

static APFloat reluF32(const APFloat &a) {
  // IEEE-754-2019 maximum: propagates NaN and orders -0.0 below +0.0, matching
  // arith.maximumf, which the Linalg lowering of relu uses.
  return llvm::maximum(a, APFloat::getZero(a.getSemantics()));
}

/// Elementwise fold of two constant operands of the same shape.
static Attribute foldBinary(Attribute lhs, Attribute rhs, Type resultType,
                            APFloat (*fn)(const APFloat &, const APFloat &)) {
  auto a = dyn_cast_or_null<DenseFPElementsAttr>(lhs);
  auto b = dyn_cast_or_null<DenseFPElementsAttr>(rhs);
  if (!a || !b)
    return {};
  auto type = cast<ShapedType>(resultType);
  if (a.isSplat() && b.isSplat())
    return DenseElementsAttr::get(
        type, fn(a.getSplatValue<APFloat>(), b.getSplatValue<APFloat>()));
  auto av = a.getValues<APFloat>();
  auto bv = b.getValues<APFloat>();
  SmallVector<APFloat> out;
  out.reserve(type.getNumElements());
  for (int64_t i = 0, e = type.getNumElements(); i < e; ++i)
    out.push_back(fn(av[i], bv[i]));
  return DenseElementsAttr::get(type, out);
}

/// True if `attr` is a splat f32 constant equal to zero with the given sign.
/// The sign matters: x + (-0.0) == x for every x, but x + (+0.0) is +0.0 when
/// x is -0.0.
static bool isSplatZero(Attribute attr, bool negative) {
  auto d = dyn_cast_or_null<DenseFPElementsAttr>(attr);
  if (!d || !d.isSplat())
    return false;
  APFloat v = d.getSplatValue<APFloat>();
  return v.isZero() && v.isNegative() == negative;
}

/// Values that can never be -0.0. relu computes maximum(x, +0.0), which is
/// +0.0 for x = -0.0, so its results are never negative zero.
static bool isNeverNegativeZero(Value v) {
  return v.getDefiningOp<ReluOp>() != nullptr;
}

OpFoldResult AddOp::fold(FoldAdaptor adaptor) {
  if (Attribute c = foldBinary(adaptor.getLhs(), adaptor.getRhs(),
                               getResult().getType(), addF32))
    return c;
  // add is Commutative, so canonicalization moves constants to the rhs; the
  // lhs case is still handled because fold() can be called directly.
  std::pair<Value, Attribute> cases[] = {{getLhs(), adaptor.getRhs()},
                                         {getRhs(), adaptor.getLhs()}};
  for (auto [x, zero] : cases) {
    if (isSplatZero(zero, /*negative=*/true))
      return x;
    if (isSplatZero(zero, /*negative=*/false) && isNeverNegativeZero(x))
      return x;
  }
  return {};
}

OpFoldResult ReluOp::fold(FoldAdaptor adaptor) {
  // relu is idempotent: relu(x) is NaN or >= +0.0, and maximum(r, +0.0) == r
  // for all such r.
  if (auto inner = getInput().getDefiningOp<ReluOp>())
    return inner.getResult();
  auto c = dyn_cast_or_null<DenseFPElementsAttr>(adaptor.getInput());
  if (!c)
    return {};
  auto type = cast<ShapedType>(getResult().getType());
  if (c.isSplat())
    return DenseElementsAttr::get(type, reluF32(c.getSplatValue<APFloat>()));
  SmallVector<APFloat> out;
  out.reserve(type.getNumElements());
  for (const APFloat &v : c.getValues<APFloat>())
    out.push_back(reluF32(v));
  return DenseElementsAttr::get(type, out);
}

OpFoldResult BiasAddOp::fold(FoldAdaptor adaptor) {
  // Adding a -0.0 bias is the identity for the same reason as in AddOp.
  if (isSplatZero(adaptor.getBias(), /*negative=*/true))
    return getInput();
  if (isSplatZero(adaptor.getBias(), /*negative=*/false) &&
      isNeverNegativeZero(getInput()))
    return getInput();
  auto in = dyn_cast_or_null<DenseFPElementsAttr>(adaptor.getInput());
  auto bias = dyn_cast_or_null<DenseFPElementsAttr>(adaptor.getBias());
  if (!in || !bias)
    return {};
  auto type = cast<ShapedType>(getResult().getType());
  int64_t n = bias.getNumElements();
  auto iv = in.getValues<APFloat>();
  auto bv = bias.getValues<APFloat>();
  SmallVector<APFloat> out;
  out.reserve(type.getNumElements());
  // Row-major layout: the last dimension varies fastest, so element i uses
  // bias[i % n].
  for (int64_t i = 0, e = type.getNumElements(); i < e; ++i)
    out.push_back(addF32(iv[i], bv[i % n]));
  return DenseElementsAttr::get(type, out);
}
