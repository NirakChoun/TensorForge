// Valid tforge IR parses, verifies, and round-trips in custom and generic form.

// RUN: tensorforge-opt %s | tensorforge-opt | FileCheck %s
// RUN: tensorforge-opt %s --mlir-print-op-generic | tensorforge-opt | FileCheck %s

// CHECK-LABEL: func.func @mlp_layer
// CHECK-SAME:    (%[[X:.*]]: tensor<64x32xf32>, %[[W:.*]]: tensor<32x16xf32>, %[[B:.*]]: tensor<16xf32>)
// CHECK:         %[[MM:.*]] = tforge.matmul %[[X]], %[[W]] : tensor<64x32xf32>, tensor<32x16xf32> -> tensor<64x16xf32>
// CHECK:         %[[BA:.*]] = tforge.bias_add %[[MM]], %[[B]] : tensor<64x16xf32>, tensor<16xf32> -> tensor<64x16xf32>
// CHECK:         %[[R:.*]] = tforge.relu %[[BA]] : tensor<64x16xf32> -> tensor<64x16xf32>
// CHECK:         return %[[R]]
func.func @mlp_layer(%x: tensor<64x32xf32>, %w: tensor<32x16xf32>,
                     %b: tensor<16xf32>) -> tensor<64x16xf32> {
  %mm = tforge.matmul %x, %w : tensor<64x32xf32>, tensor<32x16xf32> -> tensor<64x16xf32>
  %ba = tforge.bias_add %mm, %b : tensor<64x16xf32>, tensor<16xf32> -> tensor<64x16xf32>
  %r = tforge.relu %ba : tensor<64x16xf32> -> tensor<64x16xf32>
  return %r : tensor<64x16xf32>
}

// Shapes that are not multiples of anything, and ranks other than 2.
// CHECK-LABEL: func.func @odd_shapes
// CHECK:         tforge.add %{{.*}}, %{{.*}} : tensor<3x5x7xf32>, tensor<3x5x7xf32> -> tensor<3x5x7xf32>
// CHECK:         tforge.add %{{.*}}, %{{.*}} : tensor<f32>, tensor<f32> -> tensor<f32>
// CHECK:         tforge.relu %{{.*}} : tensor<17xf32> -> tensor<17xf32>
// CHECK:         tforge.matmul %{{.*}}, %{{.*}} : tensor<17x1xf32>, tensor<1x33xf32> -> tensor<17x33xf32>
// CHECK:         tforge.bias_add %{{.*}}, %{{.*}} : tensor<2x3x5xf32>, tensor<5xf32> -> tensor<2x3x5xf32>
// CHECK:         tforge.bias_add %{{.*}}, %{{.*}} : tensor<5xf32>, tensor<5xf32> -> tensor<5xf32>
func.func @odd_shapes(%a: tensor<3x5x7xf32>, %s: tensor<f32>, %v: tensor<17xf32>,
                      %p: tensor<17x1xf32>, %q: tensor<1x33xf32>,
                      %t: tensor<2x3x5xf32>, %b: tensor<5xf32>) {
  %0 = tforge.add %a, %a : tensor<3x5x7xf32>, tensor<3x5x7xf32> -> tensor<3x5x7xf32>
  %1 = tforge.add %s, %s : tensor<f32>, tensor<f32> -> tensor<f32>
  %2 = tforge.relu %v : tensor<17xf32> -> tensor<17xf32>
  %3 = tforge.matmul %p, %q : tensor<17x1xf32>, tensor<1x33xf32> -> tensor<17x33xf32>
  %4 = tforge.bias_add %t, %b : tensor<2x3x5xf32>, tensor<5xf32> -> tensor<2x3x5xf32>
  %5 = tforge.bias_add %b, %b : tensor<5xf32>, tensor<5xf32> -> tensor<5xf32>
  return
}
