//===- tensorforge-opt.cpp - TensorForge optimizer driver -----------------===//
//
// Registers every upstream MLIR dialect, extension, and pass so that the
// TensorForge pipelines can be composed with upstream passes on one command
// line. TensorForge's own dialect and passes are registered here as they are
// added in later stages.
//
//===----------------------------------------------------------------------===//

#include "TensorForge/Dialect/TForge/TForgeDialect.h"
#include "TensorForge/Passes.h"
#include "TensorForge/Pipelines.h"

#include "mlir/IR/DialectRegistry.h"
#include "mlir/IR/MLIRContext.h"
#include "mlir/InitAllDialects.h"
#include "mlir/InitAllExtensions.h"
#include "mlir/InitAllPasses.h"
#include "mlir/Tools/mlir-opt/MlirOptMain.h"

int main(int argc, char **argv) {
  mlir::registerAllPasses();
  mlir::tforge::registerTForgePasses();
  mlir::tforge::registerTForgePipelines();

  mlir::DialectRegistry registry;
  mlir::registerAllDialects(registry);
  mlir::registerAllExtensions(registry);
  registry.insert<mlir::tforge::TForgeDialect>();

  return mlir::asMainReturnCode(mlir::MlirOptMain(
      argc, argv, "TensorForge optimizer driver\n", registry));
}
