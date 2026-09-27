//===- Passes.td - TensorForge passes --------------------*- tablegen -*-===//

#ifndef TENSORFORGE_PASSES
#define TENSORFORGE_PASSES

include "mlir/Pass/PassBase.td"

def ConvertTForgeToLinalg : Pass<"convert-tforge-to-linalg", "ModuleOp"> {
  let summary = "Lower tforge ops to upstream linalg, tensor, and arith";
  let description = [{
    Dialect conversion with every tforge op illegal, so the pass fails if any
    tforge op cannot be lowered.

    - `tforge.matmul` becomes `linalg.matmul` whose init is a
      `linalg.fill` of +0.0 into a `tensor.empty`.
    - `tforge.add`, `tforge.relu`, `tforge.bias_add` become `linalg.generic`
      ops with all-parallel iterators and a `tensor.empty` init. relu uses
      `arith.maximumf` against +0.0; bias_add indexes the bias with the last
      loop dimension.
  }];
  let dependentDialects = [
    "::mlir::arith::ArithDialect",
    "::mlir::linalg::LinalgDialect",
    "::mlir::tensor::TensorDialect",
  ];
}

def TForgeTileAndFuse : Pass<"tforge-tile-and-fuse", "::mlir::func::FuncOp"> {
  let summary = "Tile the last linalg op of each chain and fuse its producers";
  let description = [{
    For each tensor-semantics linalg op whose results feed no other linalg op
    (the root), tile its parallel loops with `tile-sizes` (and its reduction
    loops of fused contractions with `tile-k` if nonzero) into scf.for loops
    and fuse the producer
    chain (for example fill and matmul feeding an epilogue) into the loop body
    with upstream `scf::tileConsumerAndFuseProducersUsingSCF`.
  }];
  let options = [
    ListOption<"tileSizes", "tile-sizes", "int64_t",
               "Tile sizes for the parallel loops of the root, outermost first">,
    Option<"tileK", "tile-k", "int64_t", /*default=*/"0",
           "Tile the reduction loop of each tiled contraction (0 = do not tile)">,
    Option<"peel", "peel", "bool", /*default=*/"false",
           "Peel the created loops so full tiles have static shapes">,
  ];
  let dependentDialects = [
    "::mlir::affine::AffineDialect",
    "::mlir::arith::ArithDialect",
    "::mlir::linalg::LinalgDialect",
    "::mlir::scf::SCFDialect",
    "::mlir::tensor::TensorDialect",
  ];
}

def TForgeVectorize : Pass<"tforge-vectorize", "::mlir::func::FuncOp"> {
  let summary = "Vectorize statically shaped register tiles with upstream linalg::vectorize";
  let description = [{
    Vectorizes every tensor-semantics linalg op with a static shape whose
    iteration space has at most `max-iterations` points. Contractions are
    emitted directly as vector.contract. Dynamically shaped ops
    (peeled remainders) are left for convert-linalg-to-loops.
  }];
  let options = [
    Option<"maxIterations", "max-iterations", "int64_t", /*default=*/"4096",
           "Largest iteration space to vectorize">,
  ];
  let dependentDialects = [
    "::mlir::arith::ArithDialect",
    "::mlir::tensor::TensorDialect",
    "::mlir::vector::VectorDialect",
  ];
}

def TForgeGpuTile : Pass<"tforge-gpu-tile", "::mlir::func::FuncOp"> {
  let summary = "Tile to GPU blocks and threads with producer fusion (Transform dialect)";
  let description = [{
    Makes the epilogue update the matmul result in place, then generates and
    runs a Transform-dialect script: tile the root to an scf.forall over
    (block-tile) tiles mapped to #gpu.block<y, x>, fuse matmul and fill into
    it, tile again with (block-tile / thread-tile) threads mapped to
    #gpu.thread<y, x>, and fuse the producers into the thread loop.
  }];
  let options = [
    ListOption<"blockTile", "block-tile", "int64_t", "Block tile (BM, BN)">,
    ListOption<"threadTile", "thread-tile", "int64_t", "Per-thread tile (TM, TN)">,
    Option<"tileK", "tile-k", "int64_t", /*default=*/"0",
           "Tile the block matmul's K loop by this size (0 = no K loop)">,
    Option<"promote", "promote", "bool", /*default=*/"false",
           "Copy the A and B tiles of each K step to workgroup (shared) memory, "
           "with the copies distributed over the block's threads">,
    Option<"printScript", "print-script", "bool", /*default=*/"false",
           "Print the generated transform script to stderr">,
  ];
  let dependentDialects = [
    "::mlir::transform::TransformDialect",
    "::mlir::gpu::GPUDialect",
    "::mlir::scf::SCFDialect",
    "::mlir::linalg::LinalgDialect",
    "::mlir::tensor::TensorDialect",
    "::mlir::affine::AffineDialect",
    "::mlir::arith::ArithDialect",
    "::mlir::bufferization::BufferizationDialect",
  ];
}

def TForgeGpuMap : Pass<"tforge-gpu-map", "::mlir::func::FuncOp"> {
  let summary = "Map block/thread scf.forall loops to a gpu.launch (Transform dialect)";
  let options = [
    ListOption<"blockDims", "block-dims", "int64_t", "Threads per block (x, y, z)">,
    Option<"printScript", "print-script", "bool", /*default=*/"false",
           "Print the generated transform script to stderr">,
  ];
  let description = [{
    After bufferization: maps the block/thread forall loops to a gpu.launch
    (upstream map_forall_to_blocks / map_nested_forall_to_threads), turns
    workgroup-memory allocations inside the launch into workgroup
    attributions, folds subviews into their users (fold-memref-alias-ops
    patterns) so that upstream hoistRedundantVectorTransfers can keep K-loop
    accumulators in registers, and lowers vector ops (contract to outer
    products, transfers to loads/stores) for the NVVM conversion.
  }];
  let dependentDialects = [
    "::mlir::transform::TransformDialect",
    "::mlir::gpu::GPUDialect",
    "::mlir::scf::SCFDialect",
    "::mlir::arith::ArithDialect",
    "::mlir::memref::MemRefDialect",
    "::mlir::vector::VectorDialect",
  ];
}

def TForgeGpuSinkConstants
    : Pass<"tforge-gpu-sink-constants", "::mlir::func::FuncOp"> {
  let summary = "Clone constants used in a gpu.launch into its body (before outlining)";
}

def TForgeGpuExtract : Pass<"tforge-gpu-extract", "::mlir::ModuleOp"> {
  let summary = "Keep only the NVVM device code and record the launch configuration";
  let description = [{
    Expects one gpu.launch_func. Moves the kernel module's contents to the top
    level, erases host code, marks kernel pointer arguments noalias, and sets
    `tforge.launch = {kernel, grid, block, args}` on the module.

    With `align-vectors`, 4 x f32 loads and stores to global memory are given
    16-byte alignment so the backend emits 128-bit accesses. The pipeline
    enables it only when the construction guarantees it: buffers are
    cudaMalloc-aligned, padded row lengths are multiples of 4 (BN, BK, TN
    multiples of 4), and every vector access starts at a column that is a
    multiple of 4 (128-bit copy distribution, TN-wide thread tiles).
  }];
  let options = [
    Option<"alignVectors", "align-vectors", "bool", /*default=*/"false",
           "Mark 4 x f32 global loads/stores as 16-byte aligned">,
  ];
  let dependentDialects = ["::mlir::LLVM::LLVMDialect"];
}

def TForgePrintIR : Pass<"tforge-print-ir", "::mlir::ModuleOp"> {
  let summary = "Print the module to stderr under a stage label (pipeline debugging)";
  let description = [{
    Inserted by the TensorForge pipelines after each named stage when their
    `print-after-each` option is set. Prints
    `// ----- tforge: after <label> -----` followed by the module. Combine with
    --mlir-print-debuginfo to see which source location each op came from.
  }];
  let options = [
    Option<"label", "label", "std::string", /*default=*/"\"\"", "Stage label">,
  ];
}

#endif // TENSORFORGE_PASSES
