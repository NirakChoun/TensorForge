#ifndef TENSORFORGE_CONVERSION_TFORGETOLINALG_H
#define TENSORFORGE_CONVERSION_TFORGETOLINALG_H

#include "mlir/IR/PatternMatch.h"

namespace mlir {
namespace tforge {

/// Patterns lowering each tforge op to linalg/tensor/arith.
void populateTForgeToLinalgPatterns(RewritePatternSet &patterns);

} // namespace tforge
} // namespace mlir

#endif // TENSORFORGE_CONVERSION_TFORGETOLINALG_H
