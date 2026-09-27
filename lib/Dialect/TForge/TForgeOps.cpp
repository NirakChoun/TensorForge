//===- TForgeOps.cpp - tforge op verifiers --------------------------------===//

#include "TensorForge/Dialect/TForge/TForgeOps.h"

#include "mlir/IR/Builders.h"
#include "mlir/IR/OpImplementation.h"
#include "llvm/ADT/STLExtras.h"

#include <string>

using namespace mlir;
using namespace mlir::tforge;

/// Renders a static shape as "64x32" (or "scalar" for rank 0) so diagnostics
/// can name shapes without repeating the element type.
static std::string shapeStr(ArrayRef<int64_t> shape) {
  if (shape.empty())
    return "scalar";
  std::string s;
  llvm::interleave(
      shape, [&](int64_t d) { s += std::to_string(d); }, [&] { s += "x"; });
  return s;
}

/// Every tforge value must be a ranked, statically shaped f32 tensor. The
/// checks run in that order so the first reported problem is the most basic.
static LogicalResult verifyTForgeTensor(Operation *op, Value v, StringRef name,
                                        RankedTensorType &out) {
  Type t = v.getType();
  auto rt = dyn_cast<RankedTensorType>(t);
  if (!rt)
    return op->emitOpError() << name << " must be a ranked tensor, but got "
                             << t;
  if (!rt.hasStaticShape())
    return op->emitOpError() << name << " must have a static shape, but got "
                             << t;
  if (!rt.getElementType().isF32())
    return op->emitOpError() << name
                             << " must have f32 elements, but has element type "
                             << rt.getElementType();
  out = rt;
  return success();
}

LogicalResult AddOp::verify() {
  RankedTensorType lhs, rhs, res;
  if (failed(verifyTForgeTensor(*this, getLhs(), "lhs", lhs)) ||
      failed(verifyTForgeTensor(*this, getRhs(), "rhs", rhs)) ||
      failed(verifyTForgeTensor(*this, getResult(), "result", res)))
    return failure();
  if (lhs.getShape() != rhs.getShape())
    return emitOpError() << "operand shapes must match (no implicit "
                            "broadcasting): lhs is "
                         << shapeStr(lhs.getShape()) << ", rhs is "
                         << shapeStr(rhs.getShape());
  if (res.getShape() != lhs.getShape())
    return emitOpError() << "result shape " << shapeStr(res.getShape())
                         << " does not match operand shape "
                         << shapeStr(lhs.getShape());
  return success();
}

LogicalResult ReluOp::verify() {
  RankedTensorType in, res;
  if (failed(verifyTForgeTensor(*this, getInput(), "input", in)) ||
      failed(verifyTForgeTensor(*this, getResult(), "result", res)))
    return failure();
  if (res.getShape() != in.getShape())
    return emitOpError() << "result shape " << shapeStr(res.getShape())
                         << " does not match input shape "
                         << shapeStr(in.getShape());
  return success();
}

LogicalResult MatmulOp::verify() {
  RankedTensorType lhs, rhs, res;
  if (failed(verifyTForgeTensor(*this, getLhs(), "lhs", lhs)) ||
      failed(verifyTForgeTensor(*this, getRhs(), "rhs", rhs)) ||
      failed(verifyTForgeTensor(*this, getResult(), "result", res)))
    return failure();
  if (lhs.getRank() != 2)
    return emitOpError() << "lhs must be rank 2 (M x K), but has rank "
                         << lhs.getRank();
  if (rhs.getRank() != 2)
    return emitOpError() << "rhs must be rank 2 (K x N), but has rank "
                         << rhs.getRank();
  if (res.getRank() != 2)
    return emitOpError() << "result must be rank 2 (M x N), but has rank "
                         << res.getRank();
  int64_t m = lhs.getDimSize(0), kl = lhs.getDimSize(1);
  int64_t kr = rhs.getDimSize(0), n = rhs.getDimSize(1);
  if (kl != kr)
    return emitOpError() << "contracting dimensions do not match: lhs is "
                         << shapeStr(lhs.getShape()) << " (K = " << kl
                         << "), rhs is " << shapeStr(rhs.getShape())
                         << " (K = " << kr << ")";
  if (res.getDimSize(0) != m || res.getDimSize(1) != n)
    return emitOpError() << "result shape must be " << m << "x" << n
                         << " (M x N), but got " << shapeStr(res.getShape());
  return success();
}

LogicalResult BiasAddOp::verify() {
  RankedTensorType in, bias, res;
  if (failed(verifyTForgeTensor(*this, getInput(), "input", in)) ||
      failed(verifyTForgeTensor(*this, getBias(), "bias", bias)) ||
      failed(verifyTForgeTensor(*this, getResult(), "result", res)))
    return failure();
  if (in.getRank() < 1)
    return emitOpError() << "input must have rank >= 1, but is a scalar";
  if (bias.getRank() != 1)
    return emitOpError() << "bias must be rank 1, but has rank "
                         << bias.getRank();
  int64_t last = in.getDimSize(in.getRank() - 1);
  if (bias.getDimSize(0) != last)
    return emitOpError() << "bias length " << bias.getDimSize(0)
                         << " does not match the last dimension of input "
                         << shapeStr(in.getShape()) << " (" << last << ")";
  if (res.getShape() != in.getShape())
    return emitOpError() << "result shape " << shapeStr(res.getShape())
                         << " does not match input shape "
                         << shapeStr(in.getShape());
  return success();
}

#define GET_OP_CLASSES
#include "TensorForge/Dialect/TForge/TForgeOps.cpp.inc"
