//===- Pipelines.cpp - TensorForge pass pipelines -------------------------===//
//
// Pipelines are assembled from registered pass names (upstream and
// TensorForge) so that the exact pipeline is printable with
// --dump-pass-pipeline and reproducible from the command line.
//
//===----------------------------------------------------------------------===//

#include "TensorForge/Pipelines.h"

#include "mlir/Pass/PassManager.h"
#include "mlir/Pass/PassRegistry.h"
#include "llvm/Support/ErrorHandling.h"
#include "llvm/Support/raw_ostream.h"

#include <string>

using namespace mlir;
using namespace mlir::tforge;

namespace {

void appendOrDie(OpPassManager &pm, const std::string &pipeline) {
  std::string err;
  llvm::raw_string_ostream os(err);
  if (failed(parsePassPipeline(pipeline, pm, os)))
    llvm::report_fatal_error(llvm::Twine("tforge pipeline: ") + os.str() +
                             "\n  in: " + pipeline);
}

} // namespace

std::string mlir::tforge::cpuPipelineString(const CpuPipelineOptions &) {
  std::string p;
  // tforge -> linalg on tensors. No CSE before bufferization: CSE merges the
  // identical tensor.empty inits of consecutive ops, which makes one-shot
  // bufferization write every op in place into one buffer. The baseline keeps
  // one buffer per op; Stage 5 measures reuse and fusion explicitly.
  p += "convert-tforge-to-linalg,canonicalize,";
  // Bufferize the whole module, including function boundaries, with identity
  // layouts so the C interface sees plain row-major memrefs. Results become
  // caller-provided out-params; a statically sized result allocation is
  // replaced by the out-param itself, so the harness owns the output buffer.
  p += "one-shot-bufferize{bufferize-function-boundaries=1 "
       "function-boundary-type-conversion=identity-layout-map},";
  p += "buffer-results-to-out-params{hoist-static-allocs=1 "
       "modify-public-functions=1},";
  p += "buffer-deallocation-pipeline,canonicalize,";
  // Loops and LLVM dialect.
  p += "convert-linalg-to-loops,expand-strided-metadata,lower-affine,"
       "convert-scf-to-cf,func.func(llvm-request-c-wrappers),";
  // Generic allocation functions let the harness count allocated bytes.
  p += "finalize-memref-to-llvm{use-generic-functions=1},";
  p += "convert-math-to-llvm,convert-arith-to-llvm,convert-cf-to-llvm,"
       "convert-func-to-llvm,convert-index-to-llvm,reconcile-unrealized-casts";
  return p;
}

void mlir::tforge::buildCpuPipeline(OpPassManager &pm,
                                    const CpuPipelineOptions &options) {
  appendOrDie(pm, cpuPipelineString(options));
}

void mlir::tforge::registerTForgePipelines() {
  PassPipelineRegistration<CpuPipelineOptions>(
      "tforge-cpu-pipeline",
      "Lower tforge to LLVM dialect for CPU execution (see docs/stage4.md)",
      buildCpuPipeline);
}
