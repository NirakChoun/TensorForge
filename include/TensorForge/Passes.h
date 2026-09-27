#ifndef TENSORFORGE_PASSES_H
#define TENSORFORGE_PASSES_H

#include "mlir/Pass/Pass.h"

namespace mlir {
namespace tforge {

#define GEN_PASS_DECL
#include "TensorForge/Passes.h.inc"

#define GEN_PASS_REGISTRATION
#include "TensorForge/Passes.h.inc"

} // namespace tforge
} // namespace mlir

#endif // TENSORFORGE_PASSES_H
