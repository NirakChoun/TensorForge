//===- Gpu.cpp - TensorForge GPU tiling, mapping, and kernel extraction ---===//
//
// tforge-gpu-tile     tensor-level block and thread tiling with producer
//                     fusion, expressed as a generated Transform-dialect
//                     script (upstream tile_using_forall and
//                     fuse_into_containing_op).
// tforge-gpu-map      after bufferization: upstream map_forall_to_blocks and
//                     map_nested_forall_to_threads, also via a generated
//                     script.
// tforge-gpu-extract  after outlining and NVVM lowering: keeps only the device
//                     code and records the launch configuration.
//
// The scripts are TensorForge's policy (tile sizes, mapping, what to fuse);
// every transformation they invoke is upstream MLIR. They are printed with
// -debug-only=tforge-gpu or through the `print-script` option.
//
//===----------------------------------------------------------------------===//

#include "TensorForge/Passes.h"

#include "mlir/Dialect/Affine/IR/AffineOps.h"
#include "mlir/Dialect/Arith/IR/Arith.h"
#include "mlir/Dialect/Bufferization/IR/Bufferization.h"
#include "mlir/Dialect/Func/IR/FuncOps.h"
#include "mlir/Dialect/GPU/IR/GPUDialect.h"
#include "mlir/Dialect/LLVMIR/LLVMDialect.h"
#include "mlir/Dialect/Linalg/Transforms/Hoisting.h"
#include "mlir/Dialect/Linalg/Transforms/Transforms.h"
#include "mlir/Pass/PassManager.h"
#include "mlir/Transforms/Passes.h"
#include "mlir/Dialect/MemRef/IR/MemRef.h"
#include "mlir/Dialect/MemRef/Transforms/Transforms.h"
#include "mlir/Dialect/Vector/IR/VectorOps.h"
#include "mlir/Dialect/Linalg/IR/Linalg.h"
#include "mlir/Dialect/SCF/IR/SCF.h"
#include "mlir/Dialect/Tensor/IR/Tensor.h"
#include "mlir/Dialect/Tensor/Transforms/Transforms.h"
#include "mlir/Dialect/Transform/IR/TransformDialect.h"
#include "mlir/Dialect/Transform/IR/TransformOps.h"
#include "mlir/Dialect/Transform/Transforms/TransformInterpreterUtils.h"
#include "mlir/IR/BuiltinOps.h"
#include "mlir/IR/IRMapping.h"
#include "mlir/Transforms/RegionUtils.h"
#include "mlir/Parser/Parser.h"
#include "mlir/Transforms/GreedyPatternRewriteDriver.h"
#include "llvm/Support/raw_ostream.h"

#include <string>

namespace mlir {
namespace tforge {
#define GEN_PASS_DEF_TFORGEGPUTILE
#define GEN_PASS_DEF_TFORGEGPUMAP
#define GEN_PASS_DEF_TFORGEGPUEXTRACT
#define GEN_PASS_DEF_TFORGEGPUSINKCONSTANTS
#include "TensorForge/Passes.h.inc"

// Defined in TileAndFuse.cpp.
void populateEpilogueIntoProducerInitPattern(RewritePatternSet &patterns);
} // namespace tforge
} // namespace mlir

using namespace mlir;

namespace {

constexpr llvm::StringLiteral kRootAttr = "tforge.root";

/// Parses `script` and applies its @__transform_main to `payload`.
LogicalResult runScript(Operation *payload, const std::string &script,
                        bool print) {
  if (print)
    llvm::errs() << "// tforge transform script\n" << script << "\n";
  OwningOpRef<ModuleOp> module =
      parseSourceString<ModuleOp>(script, payload->getContext());
  if (!module)
    return payload->emitError("tforge: failed to parse generated transform "
                              "script:\n")
           << script;
  auto entry =
      module->lookupSymbol<transform::NamedSequenceOp>("__transform_main");
  if (!entry)
    return payload->emitError("tforge: no @__transform_main in script");
  transform::TransformOptions options;
  return transform::applyTransformNamedSequence(payload, entry, *module,
                                                options);
}

std::string list(ArrayRef<int64_t> v) {
  std::string s = "[";
  for (size_t i = 0; i < v.size(); ++i)
    s += (i ? ", " : "") + std::to_string(v[i]);
  return s + "]";
}

const char *kAny = "!transform.any_op";

struct GpuTilePass : tforge::impl::TForgeGpuTileBase<GpuTilePass> {
  using Base::Base;

  void runOnOperation() override {
    func::FuncOp func = getOperation();
    MLIRContext *ctx = &getContext();
    if (blockTile.size() != 2 || threadTile.size() != 2) {
      func.emitError("tforge-gpu-tile: block-tile and thread-tile need 2 values");
      return signalPassFailure();
    }
    if (blockTile[0] % threadTile[0] || blockTile[1] % threadTile[1]) {
      func.emitError("tforge-gpu-tile: block tile must be a multiple of the "
                     "thread tile");
      return signalPassFailure();
    }

    // Make the epilogue update the matmul result in place, so the whole chain
    // is a destination chain that fuses through forall shared_outs.
    {
      RewritePatternSet patterns(ctx);
      tforge::populateEpilogueIntoProducerInitPattern(patterns);
      if (failed(applyPatternsGreedily(func, std::move(patterns))))
        return signalPassFailure();
    }

    // Root: the last linalg op (feeds no other linalg op). One per function.
    linalg::LinalgOp root;
    bool hasMatmul = false, hasFill = false;
    func.walk([&](linalg::LinalgOp op) {
      hasMatmul |= isa<linalg::MatmulOp>(op);
      hasFill |= isa<linalg::FillOp>(op);
      if (llvm::none_of(op->getUsers(), [](Operation *u) {
            return isa<linalg::LinalgOp>(u);
          }))
        root = op;
    });
    if (!root)
      return;
    if (root.getNumLoops() - root.getNumReductionLoops() != 2) {
      root->emitError("tforge-gpu-tile: expected a root with 2 parallel loops");
      return signalPassFailure();
    }
    root->setAttr(kRootAttr, UnitAttr::get(ctx));
    bool rootIsMatmul = isa<linalg::MatmulOp>(root);

    // Producers to fuse, outermost-consumer first.
    SmallVector<std::string> producers;
    if (hasMatmul && !rootIsMatmul)
      producers.push_back("linalg.matmul");
    if (hasFill)
      producers.push_back("linalg.fill");

    int64_t ty = blockTile[0] / threadTile[0], tx = blockTile[1] / threadTile[1];
    std::string s;
    llvm::raw_string_ostream os(s);
    std::string any = kAny;
    os << "module attributes {transform.with_named_sequence} {\n"
       << "transform.named_sequence @__transform_main(%arg0: " << any << ") {\n"
       << "  %root = transform.structured.match attributes{" << kRootAttr
       << "} in %arg0 : (" << any << ") -> " << any << "\n";
    // Block level: tile the root to a forall over (M, N) block tiles.
    os << "  %t0, %blk0 = transform.structured.tile_using_forall %root "
          "tile_sizes "
       << list(blockTile)
       << " (mapping = [#gpu.block<y>, #gpu.block<x>]) : (" << any << ") -> ("
       << any << ", " << any << ")\n";
    int n = 0;
    for (const std::string &p : producers) {
      os << "  %p" << n << " = transform.structured.match ops{[\"" << p
         << "\"]} in %arg0 : (" << any << ") -> " << any << "\n"
         << "  %pb" << n << ", %blk" << n + 1
         << " = transform.structured.fuse_into_containing_op %p" << n
         << " into %blk" << n << " : (" << any << ", " << any << ") -> ("
         << any << ", " << any << ")\n";
      ++n;
    }
    if (tileK > 0) {
      // Staged kernel (Stage 8): K loop inside the block, promoted operand
      // tiles, and separate thread loops for fill, matmul, and epilogue.
      if (!hasMatmul) {
        func.emitError("tforge-gpu-tile: tile-k needs a matmul");
        return signalPassFailure();
      }
      if (failed(runStaged(func, os, any, rootIsMatmul, ty, tx)))
        return signalPassFailure();
      return cleanup(func);
    }
    // Thread level: a fixed number of threads per block (static trip counts
    // for map_nested_forall_to_threads); each thread gets a thread-tile of the
    // block tile, smaller or empty at the problem edges.
    os << "  %t1, %thr0 = transform.structured.tile_using_forall %t0 "
          "num_threads "
       << list({ty, tx})
       << " (mapping = [#gpu.thread<y>, #gpu.thread<x>]) : (" << any
       << ") -> (" << any << ", " << any << ")\n";
    for (int i = 0; i < n; ++i)
      os << "  %pt" << i << ", %thr" << i + 1
         << " = transform.structured.fuse_into_containing_op %pb" << i
         << " into %thr" << i << " : (" << any << ", " << any << ") -> ("
         << any << ", " << any << ")\n";
    os << "  transform.yield\n}\n}\n";

    if (failed(runScript(func, os.str(), printScript)))
      return signalPassFailure();
    cleanup(func);
  }

  void cleanup(func::FuncOp func) {
    // Tile-sized tensor.empty for eliminate-empty-tensors; drop markers.
    RewritePatternSet patterns(&getContext());
    tensor::populateFoldTensorEmptyPatterns(patterns);
    if (failed(applyPatternsGreedily(func, std::move(patterns))))
      return signalPassFailure();
    func.walk([](Operation *op) {
      op->removeAttr(kRootAttr);
      op->removeAttr("tforge.kmatmul");
      op->removeAttr("tforge.copy_a");
      op->removeAttr("tforge.copy_b");
    });
  }

  /// Stage 8 structure, all shapes static (the problem is padded to the
  /// block and K tiles by the caller):
  ///
  ///   forall blocks (BM x BN):
  ///     forall threads: fill (TM x TN)
  ///     for k step BK:
  ///       forall threads (linear): copy A[BM x BK] -> shared   (vector width 4)
  ///       forall threads (linear): copy B[BK x BN] -> shared
  ///       forall threads: matmul (TM x TN x BK) from shared
  ///     forall threads: epilogue (TM x TN)
  LogicalResult runStaged(func::FuncOp func, llvm::raw_string_ostream &os,
                          const std::string &any, bool rootIsMatmul,
                          int64_t ty, int64_t tx) {
    MLIRContext *ctx = &getContext();
    // Script 1 so far holds block tiling and producer fusion; add K tiling of
    // the in-block matmul and mark it.
    std::string mm = rootIsMatmul ? "%t0" : "%pb0";
    os << "  %mk, %kloop = transform.structured.tile_using_for " << mm
       << " tile_sizes [0, 0, " << tileK << "] : (" << any << ") -> (" << any
       << ", " << any << ")\n"
       << "  transform.annotate %mk \"tforge.kmatmul\" : " << any << "\n"
       << "  transform.yield\n}\n}\n";
    if (failed(runScript(func, os.str(), printScript)))
      return failure();

    linalg::MatmulOp kmm;
    func.walk([&](linalg::MatmulOp op) {
      if (op->hasAttr("tforge.kmatmul"))
        kmm = op;
    });
    if (!kmm)
      return func.emitError("tforge-gpu-tile: K-tiled matmul not found");
    for (Value v : kmm->getOperands())
      if (!cast<ShapedType>(v.getType()).hasStaticShape())
        return kmm->emitError("tforge-gpu-tile: tile-k needs static tiles; "
                              "pad the problem to multiples of the block and "
                              "K tiles");

    if (promote) {
      // Copy each operand tile into a workgroup-memory tensor. Upstream
      // bufferization turns the alloc_tensor into a workgroup memref.alloc.
      OpBuilder b(kmm);
      Attribute ws =
          gpu::AddressSpaceAttr::get(ctx, gpu::AddressSpace::Workgroup);
      for (unsigned i = 0; i < 2; ++i) {
        Value src = kmm->getOperand(i);
        auto type = cast<RankedTensorType>(src.getType());
        auto alloc = bufferization::AllocTensorOp::create(
            b, kmm.getLoc(), type, ValueRange{}, Value(), Value(), ws);
        auto copy =
            linalg::CopyOp::create(b, kmm.getLoc(), src, alloc.getResult());
        copy->setAttr(i == 0 ? "tforge.copy_a" : "tforge.copy_b",
                      UnitAttr::get(ctx));
        kmm->setOperand(i, copy->getResult(0));
      }
    }

    // Script 2: distribute copies and the three compute ops over threads.
    int64_t threads = tx * ty;
    std::string s2;
    llvm::raw_string_ostream o2(s2);
    o2 << "module attributes {transform.with_named_sequence} {\n"
       << "transform.named_sequence @__transform_main(%arg0: " << any
       << ") {\n";
    if (promote) {
      for (const char *c : {"a", "b"})
        o2 << "  %c" << c
           << " = transform.structured.match attributes{tforge.copy_" << c
           << "} in %arg0 : (" << any << ") -> " << any << "\n"
           << "  %fc" << c << ", %tc" << c
           << " = transform.structured.gpu.map_copy_to_threads %c" << c
           << " total_num_threads = " << threads
           << " desired_bit_alignment = 128 : (" << any << ") -> (" << any
           << ", " << any << ")\n";
    }
    auto threadTile = [&](const std::string &handle, const std::string &name) {
      o2 << "  %" << name << "_t, %" << name
         << "_f = transform.structured.tile_using_forall " << handle
         << " num_threads [" << ty << ", " << tx
         << "] (mapping = [#gpu.thread<y>, #gpu.thread<x>]) : (" << any
         << ") -> (" << any << ", " << any << ")\n";
    };
    o2 << "  %kmm = transform.structured.match attributes{tforge.kmatmul} in "
          "%arg0 : ("
       << any << ") -> " << any << "\n";
    threadTile("%kmm", "mm");
    o2 << "  %fill = transform.structured.match ops{[\"linalg.fill\"]} in "
          "%arg0 : ("
       << any << ") -> " << any << "\n";
    threadTile("%fill", "fill");
    if (!rootIsMatmul) {
      o2 << "  %epi = transform.structured.match attributes{" << kRootAttr
         << "} in %arg0 : (" << any << ") -> " << any << "\n";
      threadTile("%epi", "epi");
    }
    o2 << "  transform.yield\n}\n}\n";
    return runScript(func, o2.str(), printScript);
  }
};

struct GpuMapPass : tforge::impl::TForgeGpuMapBase<GpuMapPass> {
  using Base::Base;

  void runOnOperation() override {
    func::FuncOp func = getOperation();
    bool hasForall = false;
    func.walk([&](scf::ForallOp) { hasForall = true; });
    if (!hasForall)
      return;
    if (blockDims.size() != 3) {
      func.emitError("tforge-gpu-map: block-dims needs 3 values");
      return signalPassFailure();
    }
    std::string any = kAny;
    std::string s;
    llvm::raw_string_ostream os(s);
    os << "module attributes {transform.with_named_sequence} {\n"
       << "transform.named_sequence @__transform_main(%arg0: " << any << ") {\n"
       << "  %l = transform.gpu.map_forall_to_blocks %arg0 generate_gpu_launch"
       << " : (" << any << ") -> " << any << "\n"
       << "  %t = transform.gpu.map_nested_forall_to_threads %l block_dims = "
       << list(blockDims) << " : (" << any << ") -> " << any << "\n"
       << "  transform.yield\n}\n}\n";
    if (failed(runScript(func, os.str(), printScript)))
      return signalPassFailure();

    // Workgroup-memory allocations inside a launch become workgroup
    // attributions (static shared memory in the kernel).
    func.walk([&](gpu::LaunchOp launch) {
      SmallVector<memref::AllocOp> allocs;
      func.walk([&](memref::AllocOp a) {
        auto ms = dyn_cast_or_null<gpu::AddressSpaceAttr>(
            a.getType().getMemorySpace());
        if (ms && ms.getValue() == gpu::AddressSpace::Workgroup)
          allocs.push_back(a);
      });
      for (memref::AllocOp a : allocs) {
        BlockArgument buf =
            launch.addWorkgroupAttribution(a.getType(), a.getLoc());
        for (Operation *u : llvm::make_early_inc_range(a->getUsers()))
          if (isa<memref::DeallocOp>(u))
            u->erase();
        a.getResult().replaceAllUsesWith(buf);
        a.erase();
      }
    });

    // Per-thread memref.copy of a static slice (the distributed copies to
    // shared memory) becomes vector transfers, i.e. vector-width global loads.
    {
      SmallVector<memref::CopyOp> copies;
      func.walk([&](memref::CopyOp c) { copies.push_back(c); });
      IRRewriter rewriter(&getContext());
      for (memref::CopyOp c : copies) {
        rewriter.setInsertionPoint(c);
        (void)linalg::vectorizeCopy(rewriter, c);
      }
    }

    // Fold subviews into loads/stores/transfers so that the accumulator's
    // transfers index the base buffer directly (upstream hoisting refuses
    // transfers on view-like sources), and CSE so that the accumulator's read
    // and write use the same index values.
    {
      RewritePatternSet patterns(&getContext());
      memref::populateFoldMemRefAliasOpPatterns(patterns);
      if (failed(applyPatternsGreedily(func, std::move(patterns))))
        return signalPassFailure();
      OpPassManager pm(func::FuncOp::getOperationName());
      pm.addPass(createCanonicalizerPass());
      pm.addPass(createCSEPass());
      if (failed(runPipeline(pm, func)))
        return signalPassFailure();
    }
    linalg::hoistRedundantVectorTransfers(func);

    // Lower vector ops to what the NVVM conversion handles.
    std::string l;
    llvm::raw_string_ostream lo(l);
    lo << "module attributes {transform.with_named_sequence} {\n"
       << "transform.named_sequence @__transform_main(%arg0: " << any
       << ") {\n"
       << "  transform.apply_patterns to %arg0 {\n"
       << "    transform.apply_patterns.vector.transfer_to_scf "
          "max_transfer_rank = 1 full_unroll = true\n"
       << "  } : " << any << "\n"
       << "  transform.apply_patterns to %arg0 {\n"
       << "    transform.apply_patterns.vector.lower_contraction "
          "lowering_strategy = outerproduct\n"
       << "    transform.apply_patterns.vector.lower_outerproduct\n"
       << "    transform.apply_patterns.vector.transfer_permutation_patterns\n"
       << "    transform.apply_patterns.vector.lower_transfer "
          "max_transfer_rank = 1\n"
       << "    transform.apply_patterns.vector.lower_broadcast\n"
       << "    transform.apply_patterns.vector.lower_shape_cast\n"
       << "    transform.apply_patterns.vector.lower_transpose\n"
       << "    transform.apply_patterns.canonicalization\n"
       << "  } : " << any << "\n"
       << "  transform.yield\n}\n}\n";
    if (failed(runScript(func, lo.str(), printScript)))
      return signalPassFailure();
  }
};

/// Clones constants used inside each gpu.launch into its body. Runs right
/// before outlining: canonicalization hoists constants out of the launch
/// (it is not isolated from above), and outlined kernels would otherwise take
/// them as operands.
struct GpuSinkConstantsPass
    : tforge::impl::TForgeGpuSinkConstantsBase<GpuSinkConstantsPass> {
  void runOnOperation() override {
    func::FuncOp func = getOperation();
    func.walk([&](gpu::LaunchOp launch) {
      Region &body = launch.getBody();
      llvm::SetVector<Value> captured;
      getUsedValuesDefinedAbove(body, captured);
      OpBuilder b(&body.front(), body.front().begin());
      for (Value v : captured) {
        Operation *def = v.getDefiningOp();
        if (!def || !def->hasTrait<OpTrait::ConstantLike>())
          continue;
        Operation *clone = b.clone(*def);
        replaceAllUsesInRegionWith(v, clone->getResult(0), body);
      }
    });

  }
};

/// Keeps only the device code of a module that went through outlining and
/// NVVM lowering, and records how to launch it:
///
///   module attributes {tforge.launch = {kernel = "...", grid = [..],
///       block = [..], args = ["arg0", "arg3", "i64:128", ...]}}
///
/// `argN` refers to the N-th argument of the host entry function (a buffer);
/// `i64:V` is an integer/index constant; `f32bits:B` is an f32 constant given
/// by its IEEE bit pattern. Kernel pointer arguments are marked noalias:
/// the TensorForge kernel ABI passes distinct, non-overlapping buffers.
struct GpuExtractPass : tforge::impl::TForgeGpuExtractBase<GpuExtractPass> {
  using Base::Base;

  void runOnOperation() override {
    ModuleOp module = getOperation();
    MLIRContext *ctx = &getContext();
    gpu::LaunchFuncOp launch;
    int count = 0;
    module.walk([&](gpu::LaunchFuncOp op) {
      launch = op;
      ++count;
    });
    if (count != 1) {
      module.emitError("tforge-gpu-extract: expected exactly one gpu.launch_func, found ")
          << count;
      return signalPassFailure();
    }

    auto constIndex = [](Value v) -> std::optional<int64_t> {
      APInt c;
      if (auto cst = v.getDefiningOp<arith::ConstantOp>())
        if (auto ia = dyn_cast<IntegerAttr>(cst.getValue()))
          return ia.getInt();
      return std::nullopt;
    };
    SmallVector<int64_t> grid, block;
    for (Value v : {launch.getGridSizeX(), launch.getGridSizeY(),
                    launch.getGridSizeZ(), launch.getBlockSizeX(),
                    launch.getBlockSizeY(), launch.getBlockSizeZ()}) {
      std::optional<int64_t> c = constIndex(v);
      if (!c) {
        launch.emitError("tforge-gpu-extract: non-constant launch size");
        return signalPassFailure();
      }
      (grid.size() < 3 ? grid : block).push_back(*c);
    }
    SmallVector<Attribute> args;
    for (Value v : launch.getKernelOperands()) {
      if (auto ba = dyn_cast<BlockArgument>(v)) {
        args.push_back(
            StringAttr::get(ctx, "arg" + std::to_string(ba.getArgNumber())));
      } else if (std::optional<int64_t> c = constIndex(v)) {
        args.push_back(StringAttr::get(ctx, "i64:" + std::to_string(*c)));
      } else if (auto cst = v.getDefiningOp<arith::ConstantOp>();
                 cst && cst.getType().isF32()) {
        // Passed by bit pattern so the value round-trips exactly.
        uint32_t bits = static_cast<uint32_t>(
            cast<FloatAttr>(cst.getValue()).getValue().bitcastToAPInt()
                .getZExtValue());
        args.push_back(StringAttr::get(ctx, "f32bits:" + std::to_string(bits)));
      } else {
        launch.emitError("tforge-gpu-extract: unsupported kernel operand");
        return signalPassFailure();
      }
    }
    std::string kernel = launch.getKernelName().str();
    auto gpuModule =
        module.lookupSymbol<gpu::GPUModuleOp>(launch.getKernelModuleName());
    if (!gpuModule) {
      launch.emitError("tforge-gpu-extract: kernel module not found");
      return signalPassFailure();
    }

    // Move the device ops to the top level and drop everything else.
    OpBuilder b(ctx);
    Block *body = module.getBody();
    SmallVector<Operation *> keep;
    for (Operation &op : gpuModule.getBody()->without_terminator())
      keep.push_back(&op);
    for (Operation *op : keep)
      op->moveBefore(body, body->end());
    SmallVector<Operation *> drop;
    for (Operation &op : *body)
      if (!llvm::is_contained(keep, &op))
        drop.push_back(&op);
    for (Operation *op : drop)
      op->erase();

    // Shared-memory arrays (workgroup attributions) are accessed with up to
    // 128-bit loads and stores; state the 16-byte alignment explicitly.
    module.walk([&](LLVM::GlobalOp g) {
      if (g.getAddrSpace() == 3 && !g.getAlignment())
        g.setAlignment(16);
    });

    if (alignVectors) {
      auto isVec4F32 = [](Type t) {
        auto v = dyn_cast<VectorType>(t);
        return v && v.getRank() == 1 && v.getNumElements() == 4 &&
               v.getElementType().isF32();
      };
      auto isGlobal = [](Value ptr) {
        auto pt = cast<LLVM::LLVMPointerType>(ptr.getType());
        return pt.getAddressSpace() == 0 || pt.getAddressSpace() == 1;
      };
      module.walk([&](LLVM::LoadOp op) {
        if (isVec4F32(op.getType()) && isGlobal(op.getAddr()))
          op.setAlignment(16);
      });
      module.walk([&](LLVM::StoreOp op) {
        if (isVec4F32(op.getValue().getType()) && isGlobal(op.getAddr()))
          op.setAlignment(16);
      });
    }

    for (auto fn : module.getOps<LLVM::LLVMFuncOp>()) {
      if (fn.getName() != kernel)
        continue;
      for (unsigned i = 0, e = fn.getNumArguments(); i < e; ++i)
        if (isa<LLVM::LLVMPointerType>(fn.getArgument(i).getType()))
          fn.setArgAttr(i, LLVM::LLVMDialect::getNoAliasAttrName(),
                        UnitAttr::get(ctx));
    }

    NamedAttrList launchInfo;
    launchInfo.append("kernel", StringAttr::get(ctx, kernel));
    launchInfo.append("grid", b.getDenseI64ArrayAttr(grid));
    launchInfo.append("block", b.getDenseI64ArrayAttr(block));
    launchInfo.append("args", ArrayAttr::get(ctx, args));
    module->setAttr("tforge.launch", DictionaryAttr::get(ctx, launchInfo));
    module->setAttr(LLVM::LLVMDialect::getTargetTripleAttrName(),
                    StringAttr::get(ctx, "nvptx64-nvidia-cuda"));
  }
};

} // namespace
