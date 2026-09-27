//===- PrintIR.cpp - labeled IR dumps for pipeline debugging --------------===//

#include "TensorForge/Passes.h"

#include "mlir/IR/BuiltinOps.h"
#include "mlir/IR/OperationSupport.h"
#include "llvm/Support/raw_ostream.h"

namespace mlir {
namespace tforge {
#define GEN_PASS_DEF_TFORGEPRINTIR
#include "TensorForge/Passes.h.inc"
} // namespace tforge
} // namespace mlir

using namespace mlir;

namespace {
struct PrintIRPass : tforge::impl::TForgePrintIRBase<PrintIRPass> {
  using Base::Base;
  void runOnOperation() override {
    llvm::errs() << "// ----- tforge: after " << label << " -----\n";
    // Honor --mlir-print-debuginfo and the other global printing flags.
    getOperation()->print(llvm::errs(), OpPrintingFlags());
    llvm::errs() << "\n";
    markAllAnalysesPreserved();
  }
};
} // namespace
