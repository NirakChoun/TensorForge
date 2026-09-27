// E4: labeled IR dumps after each TensorForge stage, with source locations.
// RUN: tensorforge-opt %s --tforge-cpu-pipeline="fuse-elementwise=1 reg-tile=6,16,4 vectorize=1 print-after-each=1" -o /dev/null 2>&1 | FileCheck %s --check-prefix=CPU
// RUN: tensorforge-opt %s --tforge-gpu-pipeline="block-tile=16,16 thread-tile=1,1 print-after-each=1" --mlir-print-debuginfo -o /dev/null 2>&1 | FileCheck %s --check-prefix=GPU

// CPU: // ----- tforge: after tforge-to-linalg -----
// CPU: linalg.matmul
// CPU: // ----- tforge: after fusion-tiling-vectorization -----
// CPU: vector.contract
// CPU: // ----- tforge: after bufferization -----
// CPU: // ----- tforge: after loops -----

// With --mlir-print-debuginfo, lowered ops keep the location of the tforge op
// they came from (the matmul on line 25 of this file).
// GPU: // ----- tforge: after tforge-to-linalg -----
// GPU: [[LOC:#loc[0-9]+]] = loc("{{.*}}print-after-each.mlir":25:9)
// GPU: linalg.matmul {{.*}} loc([[LOC]])
// GPU: // ----- tforge: after gpu-tiling -----
// GPU: // ----- tforge: after bufferization -----
// GPU: // ----- tforge: after gpu-mapping -----
// GPU: gpu.launch
// GPU: // ----- tforge: after outlining -----
// GPU: gpu.module

func.func @entry(%x: tensor<67x33xf32>, %w: tensor<33x17xf32>, %b: tensor<17xf32>) -> tensor<67x17xf32> {
  %mm = tforge.matmul %x, %w : tensor<67x33xf32>, tensor<33x17xf32> -> tensor<67x17xf32>
  %ba = tforge.bias_add %mm, %b : tensor<67x17xf32>, tensor<17xf32> -> tensor<67x17xf32>
  %r = tforge.relu %ba : tensor<67x17xf32> -> tensor<67x17xf32>
  return %r : tensor<67x17xf32>
}
