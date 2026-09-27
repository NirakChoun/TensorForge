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
  ListOption<int64_t> regTile{
      *this, "reg-tile",
      llvm::cl::desc("Second-level register tile mr,nr,kr inside the cache "
                     "tiles (peeled so full tiles are static)")};
  Option<bool> vectorize{
      *this, "vectorize",
      llvm::cl::desc("Vectorize static register tiles and lower through the "
                     "Vector dialect"),
      llvm::cl::init(false)};
};

struct GpuPipelineOptions : public PassPipelineOptions<GpuPipelineOptions> {
  Option<bool> fuseElementwise{
      *this, "fuse-elementwise",
      llvm::cl::desc("Upstream elementwise fusion of the epilogue ops"),
      llvm::cl::init(true)};
  ListOption<int64_t> blockTile{*this, "block-tile",
                                llvm::cl::desc("Block tile BM,BN (default 16,16)")};
  ListOption<int64_t> threadTile{
      *this, "thread-tile", llvm::cl::desc("Per-thread tile TM,TN (default 1,1)")};
  Option<int64_t> tileK{*this, "tile-k",
                        llvm::cl::desc("K step of the block loop (Stage 8); "
                                       "needs shapes that are multiples of the tiles"),
                        llvm::cl::init(0)};
  Option<bool> promote{*this, "promote",
                       llvm::cl::desc("Stage A/B tiles in shared memory"),
                       llvm::cl::init(false)};
  Option<bool> vectorize{*this, "vectorize",
                         llvm::cl::desc("Vectorize thread tiles and copies"),
                         llvm::cl::init(false)};
  Option<bool> printScript{
      *this, "print-script",
      llvm::cl::desc("Print the generated transform scripts to stderr"),
      llvm::cl::init(false)};
};

std::string gpuPipelineString(const GpuPipelineOptions &options);
void buildGpuPipeline(OpPassManager &pm, const GpuPipelineOptions &options);

/// The CPU pipeline as a textual pass pipeline (module-anchored elements).
std::string cpuPipelineString(const CpuPipelineOptions &options);
void buildCpuPipeline(OpPassManager &pm, const CpuPipelineOptions &options);

void registerTForgePipelines();

} // namespace tforge
} // namespace mlir

#endif // TENSORFORGE_PIPELINES_H
