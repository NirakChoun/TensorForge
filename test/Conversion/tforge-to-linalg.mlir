// RUN: tensorforge-opt %s --convert-tforge-to-linalg --split-input-file | FileCheck %s --implicit-check-not=tforge.

// CHECK-DAG: #[[ID2:.*]] = affine_map<(d0, d1) -> (d0, d1)>
// CHECK-DAG: #[[LAST2:.*]] = affine_map<(d0, d1) -> (d1)>

// CHECK-LABEL: func.func @mlp_layer
// CHECK-SAME:    (%[[X:.*]]: tensor<67x33xf32>, %[[W:.*]]: tensor<33x17xf32>, %[[B:.*]]: tensor<17xf32>)
// CHECK:         %[[Z:.*]] = arith.constant 0.000000e+00 : f32
// CHECK:         %[[E:.*]] = tensor.empty() : tensor<67x17xf32>
// CHECK:         %[[F:.*]] = linalg.fill ins(%[[Z]] : f32) outs(%[[E]] : tensor<67x17xf32>) -> tensor<67x17xf32>
// CHECK:         %[[MM:.*]] = linalg.matmul ins(%[[X]], %[[W]] : tensor<67x33xf32>, tensor<33x17xf32>) outs(%[[F]] : tensor<67x17xf32>) -> tensor<67x17xf32>
// CHECK:         %[[E2:.*]] = tensor.empty() : tensor<67x17xf32>
// CHECK:         %[[BA:.*]] = linalg.generic {indexing_maps = [#[[ID2]], #[[LAST2]], #[[ID2]]], iterator_types = ["parallel", "parallel"]}
// CHECK-SAME:      ins(%[[MM]], %[[B]] : tensor<67x17xf32>, tensor<17xf32>) outs(%[[E2]] : tensor<67x17xf32>)
// CHECK-NEXT:    ^bb0(%[[V:.*]]: f32, %[[BV:.*]]: f32, %{{.*}}: f32):
// CHECK-NEXT:      %[[S:.*]] = arith.addf %[[V]], %[[BV]] : f32
// CHECK-NEXT:      linalg.yield %[[S]] : f32
// CHECK:         %[[Z2:.*]] = arith.constant 0.000000e+00 : f32
// CHECK:         %[[E3:.*]] = tensor.empty() : tensor<67x17xf32>
// CHECK:         %[[R:.*]] = linalg.generic {indexing_maps = [#[[ID2]], #[[ID2]]], iterator_types = ["parallel", "parallel"]}
// CHECK-SAME:      ins(%[[BA]] : tensor<67x17xf32>) outs(%[[E3]] : tensor<67x17xf32>)
// CHECK-NEXT:    ^bb0(%[[V2:.*]]: f32, %{{.*}}: f32):
// CHECK-NEXT:      %[[M:.*]] = arith.maximumf %[[V2]], %[[Z2]] : f32
// CHECK-NEXT:      linalg.yield %[[M]] : f32
// CHECK:         return %[[R]]
func.func @mlp_layer(%x: tensor<67x33xf32>, %w: tensor<33x17xf32>,
                     %b: tensor<17xf32>) -> tensor<67x17xf32> {
  %mm = tforge.matmul %x, %w : tensor<67x33xf32>, tensor<33x17xf32> -> tensor<67x17xf32>
  %ba = tforge.bias_add %mm, %b : tensor<67x17xf32>, tensor<17xf32> -> tensor<67x17xf32>
  %r = tforge.relu %ba : tensor<67x17xf32> -> tensor<67x17xf32>
  return %r : tensor<67x17xf32>
}

// -----

// CHECK-DAG: #[[ID3:.*]] = affine_map<(d0, d1, d2) -> (d0, d1, d2)>
// CHECK-DAG: #[[LAST3:.*]] = affine_map<(d0, d1, d2) -> (d2)>
// CHECK-DAG: #[[ID0:.*]] = affine_map<() -> ()>

// CHECK-LABEL: func.func @ranks
// CHECK:         linalg.generic {indexing_maps = [#[[ID3]], #[[ID3]], #[[ID3]]], iterator_types = ["parallel", "parallel", "parallel"]}
// CHECK:           arith.addf
// CHECK:         linalg.generic {indexing_maps = [#[[ID3]], #[[LAST3]], #[[ID3]]], iterator_types = ["parallel", "parallel", "parallel"]}
// CHECK:           arith.addf
// CHECK:         linalg.generic {indexing_maps = [#[[ID0]], #[[ID0]], #[[ID0]]], iterator_types = []}
// CHECK:           arith.addf
func.func @ranks(%a: tensor<2x3x5xf32>, %b: tensor<5xf32>, %s: tensor<f32>)
    -> (tensor<2x3x5xf32>, tensor<2x3x5xf32>, tensor<f32>) {
  %0 = tforge.add %a, %a : tensor<2x3x5xf32>, tensor<2x3x5xf32> -> tensor<2x3x5xf32>
  %1 = tforge.bias_add %a, %b : tensor<2x3x5xf32>, tensor<5xf32> -> tensor<2x3x5xf32>
  %2 = tforge.add %s, %s : tensor<f32>, tensor<f32> -> tensor<f32>
  return %0, %1, %2 : tensor<2x3x5xf32>, tensor<2x3x5xf32>, tensor<f32>
}

// -----

// Non-tforge ops pass through unchanged.
// CHECK-LABEL: func.func @passthrough
// CHECK:         arith.addf
// CHECK:         return
func.func @passthrough(%a: f32) -> f32 {
  %0 = arith.addf %a, %a : f32
  return %0 : f32
}
