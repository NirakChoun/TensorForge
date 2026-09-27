// The GPU pipeline: block tiles 16x16, one output per thread. 67x17 is not a
// multiple of 16, so edge blocks and threads get partial or empty tiles.
// RUN: tensorforge-opt %s --tforge-gpu-pipeline="block-tile=16,16 thread-tile=1,1" --mlir-print-ir-before=one-shot-bufferize -o /dev/null 2>&1 | FileCheck %s --check-prefix=TENSOR
// RUN: tensorforge-opt %s --tforge-gpu-pipeline="block-tile=16,16 thread-tile=1,1" | FileCheck %s --check-prefix=DEVICE
// RUN: tensorforge-opt %s --tforge-gpu-pipeline="block-tile=16,16 thread-tile=1,1" | mlir-translate --mlir-to-llvmir | FileCheck %s --check-prefix=LLVMIR

// Tensor level: block forall over ceil(67/16) x ceil(17/16) tiles, 16x16
// thread forall inside, and the fused fill -> matmul -> epilogue chain writing
// the thread's slice of the shared output (no temporaries).
// TENSOR:     scf.forall (%{{.*}}, %{{.*}}) in (5, 2) shared_outs(%[[BO:.*]] = %{{.*}}) -> (tensor<67x17xf32>)
// TENSOR:       scf.forall (%{{.*}}, %{{.*}}) in (16, 16) shared_outs(%[[TO:.*]] = %{{.*}}) -> (tensor<?x?xf32>)
// TENSOR:         %[[DST:.*]] = tensor.extract_slice %[[TO]]
// TENSOR:         %[[F:.*]] = linalg.fill ins(%{{.*}} : f32) outs(%[[DST]] : tensor<?x?xf32>)
// TENSOR:         %[[MM:.*]] = linalg.matmul ins(%{{.*}}, %{{.*}} : tensor<?x33xf32>, tensor<33x?xf32>) outs(%[[F]] : tensor<?x?xf32>)
// TENSOR:         %[[EPI:.*]] = linalg.generic {{.*}} ins(%{{.*}} : tensor<?xf32>) outs(%[[MM]] : tensor<?x?xf32>)
// TENSOR:         tensor.parallel_insert_slice %[[EPI]] into %[[TO]]
// TENSOR:       } {mapping = [#gpu.thread<y>, #gpu.thread<x>]}
// TENSOR:     } {mapping = [#gpu.block<y>, #gpu.block<x>]}

// Device module only, with the launch configuration and noalias buffers.
// DEVICE:     module attributes {{{.*}}tforge.launch = {args = ["arg2", "arg0", "arg1", "arg3"{{.*}}], block = array<i64: 16, 16, 1>, grid = array<i64: 2, 5, 1>, kernel = "entry_kernel"}
// DEVICE-NOT: func.func
// DEVICE-NOT: gpu.launch
// DEVICE:     llvm.func @entry_kernel(%{{.*}}: !llvm.ptr {llvm.noalias}, %{{.*}}: !llvm.ptr {llvm.noalias}, %{{.*}}: !llvm.ptr {llvm.noalias}, %{{.*}}: !llvm.ptr {llvm.noalias}
// DEVICE-SAME:  nvvm.kernel
// DEVICE:       nvvm.read.ptx.sreg.ctaid.x
// DEVICE:       nvvm.read.ptx.sreg.tid.x
// DEVICE-NOT: llvm.call @memrefCopy

// LLVMIR: define ptx_kernel void @entry_kernel(ptr noalias %0, ptr noalias %1, ptr noalias %2, ptr noalias %3

func.func @entry(%x: tensor<67x33xf32>, %w: tensor<33x17xf32>, %b: tensor<17xf32>) -> tensor<67x17xf32> {
  %mm = tforge.matmul %x, %w : tensor<67x33xf32>, tensor<33x17xf32> -> tensor<67x17xf32>
  %ba = tforge.bias_add %mm, %b : tensor<67x17xf32>, tensor<17xf32> -> tensor<67x17xf32>
  %r = tforge.relu %ba : tensor<67x17xf32> -> tensor<67x17xf32>
  return %r : tensor<67x17xf32>
}
