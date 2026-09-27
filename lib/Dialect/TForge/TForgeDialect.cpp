#include "TensorForge/Dialect/TForge/TForgeDialect.h"
#include "TensorForge/Dialect/TForge/TForgeOps.h"

#include "mlir/Dialect/Arith/IR/Arith.h"

using namespace mlir;
using namespace mlir::tforge;

#include "TensorForge/Dialect/TForge/TForgeOpsDialect.cpp.inc"

void TForgeDialect::initialize() {
  addOperations<
#define GET_OP_LIST
#include "TensorForge/Dialect/TForge/TForgeOps.cpp.inc"
      >();
}

Operation *TForgeDialect::materializeConstant(OpBuilder &builder,
                                              Attribute value, Type type,
                                              Location loc) {
  return arith::ConstantOp::materialize(builder, value, type, loc);
}
