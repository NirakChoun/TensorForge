#ifndef TENSORFORGE_PIPELINES_H
#define TENSORFORGE_PIPELINES_H

#include "mlir/Pass/PassOptions.h"

#include <string>

namespace mlir {
class OpPassManager;
namespace tforge {

struct CpuPipelineOptions : public PassPipelineOptions<CpuPipelineOptions> {};

/// The CPU pipeline as a textual pass pipeline (module-anchored elements).
std::string cpuPipelineString(const CpuPipelineOptions &options);
void buildCpuPipeline(OpPassManager &pm, const CpuPipelineOptions &options);

void registerTForgePipelines();

} // namespace tforge
} // namespace mlir

#endif // TENSORFORGE_PIPELINES_H
