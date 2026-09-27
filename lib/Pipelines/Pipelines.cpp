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

namespace {
std::string joinSizes(ArrayRef<int64_t> sizes) {
  std::string s;
  for (size_t i = 0; i < sizes.size(); ++i)
    s += (i ? "," : "") + std::to_string(sizes[i]);
  return s;
}
} // namespace

std::string mlir::tforge::cpuPipelineString(const CpuPipelineOptions &o) {
  std::string p;
  bool tiled = !o.tileSizes.empty();
  if (o.vectorize && o.regTile.empty())
    llvm::report_fatal_error("tforge-cpu-pipeline: vectorize requires reg-tile");
  // tforge -> linalg on tensors. No CSE before bufferization: CSE merges the
  // identical tensor.empty inits of consecutive ops, which makes one-shot
  // bufferization write every op in place into one buffer. The baseline keeps
  // one buffer per op; Stage 5 measures reuse and fusion explicitly.
  p += "convert-tforge-to-linalg,canonicalize,";
  if (o.reuse)
    p += "cse,";
  if (o.fuseElementwise)
    p += "linalg-fuse-elementwise-ops,canonicalize,";
  if (tiled) {
    p += "func.func(tforge-tile-and-fuse{tile-sizes=" +
         joinSizes(o.tileSizes) + " tile-k=" + std::to_string(o.tileK) +
         "}),canonicalize,";
  }
  if (!o.regTile.empty()) {
    ArrayRef<int64_t> r = o.regTile;
    int64_t kr = r.size() > 2 ? r[2] : 0;
    p += "func.func(tforge-tile-and-fuse{tile-sizes=" +
         joinSizes(r.take_front(std::min<size_t>(2, r.size()))) +
         " tile-k=" + std::to_string(kr) + " peel=1}),canonicalize,";
  }
  // Vectorize register tiles; then move the K-loop accumulator read/write out
  // of the loop so it stays in registers (loop-carried vector).
  if (o.vectorize)
    p += "func.func(tforge-vectorize),canonicalize,"
         "loop-invariant-subset-hoisting,canonicalize,";
  if (tiled || !o.regTile.empty()) {
    // No CSE here: it would merge the fill's tensor.empty with the output's,
    // which forces a full-size temporary and a copy after bufferization.
    // Empty-tensor elimination makes the fused tile chain write in place.
    p += "eliminate-empty-tensors,";
  }
  // Bufferize the whole module, including function boundaries, with identity
  // layouts so the C interface sees plain row-major memrefs. Results become
  // caller-provided out-params; a statically sized result allocation is
  // replaced by the out-param itself, so the harness owns the output buffer.
  p += "one-shot-bufferize{bufferize-function-boundaries=1 "
       "function-boundary-type-conversion=identity-layout-map},";
  // Tiled loops carry the result buffer as an scf.for iter_arg; canonicalize
  // folds the loop-carried memref so the function returns the allocation
  // itself, which buffer-results-to-out-params can then replace with the
  // out-param (otherwise it copies the whole result at the end).
  p += "canonicalize,";
  p += "buffer-results-to-out-params{hoist-static-allocs=1 "
       "modify-public-functions=1},";
  // Tile-sized temporaries are allocated inside the tile loop; hoist them so
  // each call allocates one tile buffer instead of one per iteration.
  if (tiled)
    p += "func.func(buffer-loop-hoisting),";
  p += "buffer-deallocation-pipeline,canonicalize,";
  // Loops and LLVM dialect.
  p += "convert-linalg-to-loops,";
  if (o.vectorize)
    p += "func.func(lower-vector-multi-reduction),convert-vector-to-scf,";
  p += "expand-strided-metadata,lower-affine,convert-scf-to-cf,"
       "func.func(llvm-request-c-wrappers),";
  // Contractions become vector.outerproduct and then vector.fma per row.
  if (o.vectorize)
    p += "convert-vector-to-llvm{vector-contract-lowering=outerproduct},";
  // Generic allocation functions let the harness count allocated bytes.
  p += "finalize-memref-to-llvm{use-generic-functions=1},";
  p += "convert-math-to-llvm,convert-arith-to-llvm,convert-cf-to-llvm,"
       "convert-func-to-llvm,convert-index-to-llvm,convert-ub-to-llvm,"
       "reconcile-unrealized-casts";
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
