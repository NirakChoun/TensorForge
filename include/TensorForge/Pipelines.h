#ifndef TENSORFORGE_PIPELINES_H
#define TENSORFORGE_PIPELINES_H

#include "mlir/Pass/PassOptions.h"

#include <string>

namespace mlir {
class OpPassManager;
namespace tforge {

struct CpuPipelineOptions : public PassPipelineOptions<CpuPipelineOptions> {
  Option<bool> reuse{
      *this, "reuse",
      llvm::cl::desc("CSE tensor.empty inits before bufferization so every "
                     "op writes in place into one buffer (no fusion)"),
      llvm::cl::init(false)};
  Option<bool> fuseElementwise{
      *this, "fuse-elementwise",
      llvm::cl::desc("Upstream elementwise fusion of the epilogue ops "
                     "(bias_add + relu into one linalg.generic)"),
      llvm::cl::init(false)};
  ListOption<int64_t> tileSizes{
      *this, "tile-sizes",
      llvm::cl::desc("Tile the parallel loops of each root op and fuse its "
                     "producers into the tile loop (tforge-tile-and-fuse)")};
  Option<int64_t> tileK{*this, "tile-k",
                        llvm::cl::desc("Also tile the reduction loop"),
                        llvm::cl::init(0)};
};

/// The CPU pipeline as a textual pass pipeline (module-anchored elements).
std::string cpuPipelineString(const CpuPipelineOptions &options);
void buildCpuPipeline(OpPassManager &pm, const CpuPipelineOptions &options);

void registerTForgePipelines();

} // namespace tforge
} // namespace mlir

#endif // TENSORFORGE_PIPELINES_H
