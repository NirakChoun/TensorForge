// RUN: tensorforge-opt %s --split-input-file --pass-pipeline="builtin.module(func.func(tforge-vectorize{max-iterations=4096}))" | FileCheck %s

// A static register tile: fill, matmul (6x16x1), and an in-place epilogue
// become vector ops; the matmul becomes a vector.contract directly.
// CHECK-LABEL: func.func @register_tile
// CHECK-NOT:     linalg.
// CHECK:         vector.transfer_write %{{.*}} : vector<6x16xf32>, tensor<6x16xf32>
// CHECK:         vector.transfer_read {{.*}} : tensor<6x1xf32>, vector<6x1xf32>
// CHECK:         vector.transfer_read {{.*}} : tensor<1x16xf32>, vector<1x16xf32>
// CHECK:         vector.contract {{.*}}iterator_types = ["parallel", "parallel", "reduction"]{{.*}} : vector<6x1xf32>, vector<1x16xf32> into vector<6x16xf32>
// CHECK:         arith.addf {{.*}} : vector<6x16xf32>
// CHECK:         arith.maximumf {{.*}} : vector<6x16xf32>
#id = affine_map<(d0, d1) -> (d0, d1)>
#last = affine_map<(d0, d1) -> (d1)>
func.func @register_tile(%a: tensor<6x1xf32>, %b: tensor<1x16xf32>, %bias: tensor<16xf32>) -> tensor<6x16xf32> {
  %zero = arith.constant 0.0 : f32
  %e = tensor.empty() : tensor<6x16xf32>
  %f = linalg.fill ins(%zero : f32) outs(%e : tensor<6x16xf32>) -> tensor<6x16xf32>
  %mm = linalg.matmul ins(%a, %b : tensor<6x1xf32>, tensor<1x16xf32>) outs(%f : tensor<6x16xf32>) -> tensor<6x16xf32>
  %r = linalg.generic {indexing_maps = [#last, #id], iterator_types = ["parallel", "parallel"]}
      ins(%bias : tensor<16xf32>) outs(%mm : tensor<6x16xf32>) {
  ^bb0(%in: f32, %out: f32):
    %s = arith.addf %out, %in : f32
    %m = arith.maximumf %s, %zero : f32
    linalg.yield %m : f32
  } -> tensor<6x16xf32>
  return %r : tensor<6x16xf32>
}

// -----

// Dynamic shapes (peeled remainders) are not vectorized.
// CHECK-LABEL: func.func @dynamic_left_alone
// CHECK:         linalg.matmul
// CHECK-NOT:     vector.contract
func.func @dynamic_left_alone(%a: tensor<?x4xf32>, %b: tensor<4x16xf32>, %c: tensor<?x16xf32>) -> tensor<?x16xf32> {
  %mm = linalg.matmul ins(%a, %b : tensor<?x4xf32>, tensor<4x16xf32>) outs(%c : tensor<?x16xf32>) -> tensor<?x16xf32>
  return %mm : tensor<?x16xf32>
}

// -----

// Iteration spaces above max-iterations (here 64*64*64) are not vectorized:
// only register tiles should become vectors.
// CHECK-LABEL: func.func @too_large
// CHECK:         linalg.matmul
// CHECK-NOT:     vector.contract
func.func @too_large(%a: tensor<64x64xf32>, %b: tensor<64x64xf32>, %c: tensor<64x64xf32>) -> tensor<64x64xf32> {
  %mm = linalg.matmul ins(%a, %b : tensor<64x64xf32>, tensor<64x64xf32>) outs(%c : tensor<64x64xf32>) -> tensor<64x64xf32>
  return %mm : tensor<64x64xf32>
}
