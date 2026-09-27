#ifndef TENSORFORGE_DIALECT_TFORGE_TFORGEOPS_H
#define TENSORFORGE_DIALECT_TFORGE_TFORGEOPS_H

#include "mlir/IR/BuiltinTypes.h"
#include "mlir/IR/Dialect.h"
#include "mlir/IR/OpDefinition.h"
#include "mlir/Interfaces/SideEffectInterfaces.h"

#include "TensorForge/Dialect/TForge/TForgeDialect.h"

#define GET_OP_CLASSES
#include "TensorForge/Dialect/TForge/TForgeOps.h.inc"

#endif // TENSORFORGE_DIALECT_TFORGE_TFORGEOPS_H
