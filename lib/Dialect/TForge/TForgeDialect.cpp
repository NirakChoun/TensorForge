#include "TensorForge/Dialect/TForge/TForgeDialect.h"
#include "TensorForge/Dialect/TForge/TForgeOps.h"

using namespace mlir;
using namespace mlir::tforge;

#include "TensorForge/Dialect/TForge/TForgeOpsDialect.cpp.inc"

void TForgeDialect::initialize() {
  addOperations<
#define GET_OP_LIST
#include "TensorForge/Dialect/TForge/TForgeOps.cpp.inc"
      >();
}
