// Parse, print, and re-parse upstream IR through tensorforge-opt, in both the
// custom and the generic op syntax, to show the driver registers the dialects
// later stages lower into.

// RUN: tensorforge-opt %s | tensorforge-opt | FileCheck %s
// RUN: tensorforge-opt %s --mlir-print-op-generic | tensorforge-opt | FileCheck %s

// CHECK-LABEL: func.func @matmul_bias_relu
// CHECK-SAME:    (%[[A:.*]]: tensor<64x32xf32>, %[[B:.*]]: tensor<32x16xf32>, %[[BIAS:.*]]: tensor<16xf32>) -> tensor<64x16xf32>
// CHECK:         %[[ZERO:.*]] = arith.constant 0.000000e+00 : f32
// CHECK:         %[[EMPTY:.*]] = tensor.empty() : tensor<64x16xf32>
// CHECK:         %[[FILL:.*]] = linalg.fill ins(%[[ZERO]] : f32) outs(%[[EMPTY]] : tensor<64x16xf32>)
// CHECK:         %[[MM:.*]] = linalg.matmul ins(%[[A]], %[[B]] : tensor<64x32xf32>, tensor<32x16xf32>) outs(%[[FILL]] : tensor<64x16xf32>)
// CHECK:         linalg.generic
// CHECK-SAME:      ins(%[[MM]], %[[BIAS]] : tensor<64x16xf32>, tensor<16xf32>)
// CHECK:           arith.addf
// CHECK:           arith.maximumf
// CHECK:           linalg.yield
// CHECK:         return

#map_mn = affine_map<(m, n) -> (m, n)>
#map_n = affine_map<(m, n) -> (n)>

func.func @matmul_bias_relu(%a: tensor<64x32xf32>, %b: tensor<32x16xf32>,
                            %bias: tensor<16xf32>) -> tensor<64x16xf32> {
  %zero = arith.constant 0.0 : f32
  %empty = tensor.empty() : tensor<64x16xf32>
  %fill = linalg.fill ins(%zero : f32) outs(%empty : tensor<64x16xf32>) -> tensor<64x16xf32>
  %mm = linalg.matmul ins(%a, %b : tensor<64x32xf32>, tensor<32x16xf32>)
                      outs(%fill : tensor<64x16xf32>) -> tensor<64x16xf32>
  %out = linalg.generic {indexing_maps = [#map_mn, #map_n, #map_mn],
                         iterator_types = ["parallel", "parallel"]}
      ins(%mm, %bias : tensor<64x16xf32>, tensor<16xf32>)
      outs(%empty : tensor<64x16xf32>) {
  ^bb0(%x: f32, %bv: f32, %o: f32):
    %s = arith.addf %x, %bv : f32
    %r = arith.maximumf %s, %zero : f32
    linalg.yield %r : f32
  } -> tensor<64x16xf32>
  return %out : tensor<64x16xf32>
}
