// Heap allocations left in the final code for each Stage 5 variant of
// relu(matmul + bias). The out-param is caller-owned and never counted.
// RUN: tensorforge-opt %s --tforge-cpu-pipeline | FileCheck %s --check-prefix=BASE
// RUN: tensorforge-opt %s --tforge-cpu-pipeline="reuse=1" | FileCheck %s --check-prefix=NONE
// RUN: tensorforge-opt %s --tforge-cpu-pipeline="fuse-elementwise=1" | FileCheck %s --check-prefix=ONE
// RUN: tensorforge-opt %s --tforge-cpu-pipeline="fuse-elementwise=1 tile-sizes=32,32" | FileCheck %s --check-prefix=NONE

// Baseline: matmul result and bias_add result are separate buffers.
// BASE-COUNT-2: llvm.call @_mlir_memref_to_llvm_alloc(
// BASE-NOT:     llvm.call @_mlir_memref_to_llvm_alloc(

// Elementwise fusion only: the matmul result is still materialized.
// ONE-COUNT-1: llvm.call @_mlir_memref_to_llvm_alloc(
// ONE-NOT:     llvm.call @_mlir_memref_to_llvm_alloc(

// CSE reuse and tile-and-fuse: no temporary buffers.
// NONE-NOT: llvm.call @_mlir_memref_to_llvm_alloc(
// NONE-NOT: llvm.call @memcpy

func.func @entry(%x: tensor<67x33xf32>, %w: tensor<33x17xf32>, %b: tensor<17xf32>) -> tensor<67x17xf32> {
  %mm = tforge.matmul %x, %w : tensor<67x33xf32>, tensor<33x17xf32> -> tensor<67x17xf32>
  %ba = tforge.bias_add %mm, %b : tensor<67x17xf32>, tensor<17xf32> -> tensor<67x17xf32>
  %r = tforge.relu %ba : tensor<67x17xf32> -> tensor<67x17xf32>
  return %r : tensor<67x17xf32>
}
