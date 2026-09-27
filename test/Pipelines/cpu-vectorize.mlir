// The vectorized CPU pipeline: register tiles 6x16x1 inside 64x64 cache
// tiles. 250x330x170 is not a multiple of any tile size, so peeled remainders
// exist next to the vectorized full tiles.
// RUN: tensorforge-opt %s --tforge-cpu-pipeline="fuse-elementwise=1 tile-sizes=64,64 reg-tile=6,16,1 vectorize=1" --mlir-print-ir-before=one-shot-bufferize -o /dev/null 2>&1 | FileCheck %s --check-prefix=TENSOR
// RUN: tensorforge-opt %s --tforge-cpu-pipeline="fuse-elementwise=1 tile-sizes=64,64 reg-tile=6,16,1 vectorize=1" | FileCheck %s --check-prefix=LLVM

// Before bufferization: the K loop carries the 6x16 accumulator as a vector
// (loop-invariant-subset-hoisting), starting from a zero vector (the fill),
// and the bias + relu epilogue is applied to the loop result in registers.
// TENSOR:     %[[ACC:.*]] = scf.for %{{.*}} = %{{.*}} to %{{.*}} step %{{.*}} iter_args(%[[IT:.*]] = %{{.*}}) -> (vector<6x16xf32>)
// TENSOR:       vector.transfer_read {{.*}} vector<6x1xf32>
// TENSOR:       vector.transfer_read {{.*}} vector<1x16xf32>
// TENSOR:       %[[C:.*]] = vector.contract {{.*}} %[[IT]] : vector<6x1xf32>, vector<1x16xf32> into vector<6x16xf32>
// TENSOR:       scf.yield %[[C]] : vector<6x16xf32>
// TENSOR:     %[[S:.*]] = arith.addf %[[ACC]], %{{.*}} : vector<6x16xf32>
// TENSOR:     arith.maximumf %[[S]], %{{.*}} : vector<6x16xf32>
// Remainder tiles stay as (dynamically shaped) linalg ops.
// TENSOR:     linalg.matmul {{.*}} tensor<?x

// Final code: 16-wide multiply-adds (llvm.intr.fmuladd; x86 codegen fuses them into vfmadd231ps) from the outer-product lowering, no temporaries.
// LLVM:     llvm.intr.fmuladd({{.*}}) : (vector<16xf32>, vector<16xf32>, vector<16xf32>) -> vector<16xf32>
// LLVM-NOT: llvm.call @_mlir_memref_to_llvm_alloc(

func.func @entry(%x: tensor<250x170xf32>, %w: tensor<170x330xf32>, %b: tensor<330xf32>) -> tensor<250x330xf32> {
  %mm = tforge.matmul %x, %w : tensor<250x170xf32>, tensor<170x330xf32> -> tensor<250x330xf32>
  %ba = tforge.bias_add %mm, %b : tensor<250x330xf32>, tensor<330xf32> -> tensor<250x330xf32>
  %r = tforge.relu %ba : tensor<250x330xf32> -> tensor<250x330xf32>
  return %r : tensor<250x330xf32>
}
