// The CPU pipeline lowers tforge all the way to the LLVM dialect, with the
// result as a caller-provided out-param and a C interface wrapper.
// RUN: tensorforge-opt %s --tforge-cpu-pipeline | FileCheck %s
// RUN: tensorforge-opt %s --tforge-cpu-pipeline | mlir-translate --mlir-to-llvmir | FileCheck %s --check-prefix=LLVMIR

// Only LLVM dialect remains.
// CHECK-NOT: tforge.
// CHECK-NOT: linalg.
// CHECK-NOT: memref.
// CHECK-NOT: scf.
// CHECK-DAG: llvm.func @_mlir_memref_to_llvm_alloc
// CHECK-DAG: llvm.func @_mlir_memref_to_llvm_free
// CHECK-DAG: llvm.func @entry(
// CHECK-DAG: llvm.func @_mlir_ciface_entry(%{{.*}}: !llvm.ptr, %{{.*}}: !llvm.ptr, %{{.*}}: !llvm.ptr, %{{.*}}: !llvm.ptr)

// LLVMIR: define void @_mlir_ciface_entry(ptr %0, ptr %1, ptr %2, ptr %3)

func.func @entry(%x: tensor<67x33xf32>, %w: tensor<33x17xf32>, %b: tensor<17xf32>) -> tensor<67x17xf32> {
  %mm = tforge.matmul %x, %w : tensor<67x33xf32>, tensor<33x17xf32> -> tensor<67x17xf32>
  %ba = tforge.bias_add %mm, %b : tensor<67x17xf32>, tensor<17xf32> -> tensor<67x17xf32>
  %r = tforge.relu %ba : tensor<67x17xf32> -> tensor<67x17xf32>
  return %r : tensor<67x17xf32>
}
