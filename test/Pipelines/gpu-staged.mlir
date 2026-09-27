// Stage 8 staged kernel: 64x64 block tiles, 4x4 thread tiles, K step 16,
// operand tiles in shared memory, vectorized thread tiles and copies.
// RUN: tensorforge-opt %s --split-input-file --tforge-gpu-pipeline="block-tile=64,64 thread-tile=4,4 tile-k=16 promote=1 vectorize=1" --mlir-print-ir-before=one-shot-bufferize -o /dev/null 2>&1 | FileCheck %s --check-prefix=TENSOR
// RUN: tensorforge-opt %s --tforge-gpu-pipeline="block-tile=64,64 thread-tile=4,4 tile-k=16 promote=1 vectorize=1" | FileCheck %s --check-prefix=DEVICE
// RUN: not tensorforge-opt %s --split-input-file --tforge-gpu-pipeline="block-tile=64,48 thread-tile=4,4 tile-k=16 promote=1" -o /dev/null 2>&1 | FileCheck %s --check-prefix=NOTPADDED

// TENSOR:     scf.forall (%{{.*}}, %{{.*}}) in (2, 2) shared_outs
// Fill by 16x16 threads, then the K loop over the block's accumulator tile.
// TENSOR:       scf.forall (%{{.*}}, %{{.*}}) in (16, 16)
// TENSOR:       } {mapping = [#gpu.thread<y>, #gpu.thread<x>]}
// TENSOR:       scf.for %{{.*}} = %c0 to %c64 step %c16 iter_args(%{{.*}}) -> (tensor<64x64xf32>)
// TENSOR:         bufferization.alloc_tensor() {memory_space = #gpu.address_space<workgroup>} : tensor<64x16xf32>
// TENSOR:         scf.forall
// TENSOR:         } {mapping = [#gpu.thread<linear_dim_1>, #gpu.thread<linear_dim_0>]}
// TENSOR:         bufferization.alloc_tensor() {memory_space = #gpu.address_space<workgroup>} : tensor<16x64xf32>
// TENSOR:         scf.forall
// TENSOR:         } {mapping = [#gpu.thread<linear_dim_1>, #gpu.thread<linear_dim_0>]}
// Per-thread 4x4 register tile over the K step, from the shared tiles.
// TENSOR:         scf.forall (%{{.*}}, %{{.*}}) in (16, 16)
// TENSOR:           vector.contract {{.*}} : vector<4x16xf32>, vector<16x4xf32> into vector<4x4xf32>
// TENSOR:         } {mapping = [#gpu.thread<y>, #gpu.thread<x>]}
// Epilogue by 16x16 threads after the K loop.
// TENSOR:       scf.forall (%{{.*}}, %{{.*}}) in (16, 16)
// TENSOR:       } {mapping = [#gpu.thread<y>, #gpu.thread<x>]}
// TENSOR:     } {mapping = [#gpu.block<y>, #gpu.block<x>]}

// Device code: two 64x16 / 16x64 shared arrays (addr_space 3, 16-byte
// aligned), 128-bit global accesses, barriers, and no vector-dialect ops left.
// DEVICE-DAG: llvm.mlir.global internal @__wg_entry_kernel_0() {addr_space = 3 : i32, alignment = 16 : i64} : !llvm.array<1024 x f32>
// DEVICE-DAG: llvm.mlir.global internal @__wg_entry_kernel_1() {addr_space = 3 : i32, alignment = 16 : i64} : !llvm.array<1024 x f32>
// DEVICE-DAG: llvm.load %{{.*}} {alignment = 16 : i64} : !llvm.ptr -> vector<4xf32>
// DEVICE-DAG: llvm.store %{{.*}}, %{{.*}} {alignment = 16 : i64} : vector<4xf32>, !llvm.ptr
// DEVICE-DAG: nvvm.barrier
// DEVICE-NOT: vector.transfer
// DEVICE-NOT: vector.contract

// N = 128 is not a multiple of BN = 48: the staged kernel requires the caller
// to pad the problem.
// NOTPADDED: error: tforge-gpu-tile: tile-k needs static tiles; pad the problem to multiples of the block and K tiles

func.func @entry(%x: tensor<128x64xf32>, %w: tensor<64x128xf32>, %b: tensor<128xf32>) -> tensor<128x128xf32> {
  %mm = tforge.matmul %x, %w : tensor<128x64xf32>, tensor<64x128xf32> -> tensor<128x128xf32>
  %ba = tforge.bias_add %mm, %b : tensor<128x128xf32>, tensor<128xf32> -> tensor<128x128xf32>
  %r = tforge.relu %ba : tensor<128x128xf32> -> tensor<128x128xf32>
  return %r : tensor<128x128xf32>
}
