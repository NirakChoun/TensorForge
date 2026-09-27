// RUN: tensorforge-opt %s --split-input-file \
// RUN:   --pass-pipeline="builtin.module(convert-tforge-to-linalg,canonicalize,linalg-fuse-elementwise-ops,canonicalize,func.func(tforge-tile-and-fuse{tile-sizes=32,32}),canonicalize)" \
// RUN:   | FileCheck %s

// relu(matmul + bias): upstream elementwise fusion makes one epilogue generic;
// tforge-tile-and-fuse tiles it (M by 32; N=17 fits one tile), fuses the fill
// and matmul into the loop, and rewrites the epilogue to update the matmul tile
// in place. The fill starts from a tile-sized tensor.empty.
// CHECK-LABEL: func.func @mbr
// CHECK-SAME:    (%[[A:.*]]: tensor<67x33xf32>, %[[B:.*]]: tensor<33x17xf32>, %[[BIAS:.*]]: tensor<17xf32>)
// CHECK:         %[[OUT:.*]] = tensor.empty() : tensor<67x17xf32>
// CHECK:         scf.for %[[I:.*]] = %{{.*}} to %{{.*}} step %{{.*}} iter_args(%[[ACC:.*]] = %[[OUT]])
// CHECK:           %[[SZ:.*]] = affine.min
// CHECK:           %[[AT:.*]] = tensor.extract_slice %[[A]][%[[I]], 0] [%[[SZ]], 33]
// CHECK:           %[[E:.*]] = tensor.empty(%[[SZ]]) : tensor<?x17xf32>
// CHECK:           %[[F:.*]] = linalg.fill ins(%{{.*}} : f32) outs(%[[E]] : tensor<?x17xf32>)
// CHECK:           %[[MM:.*]] = linalg.matmul ins(%[[AT]], %[[B]] : tensor<?x33xf32>, tensor<33x17xf32>) outs(%[[F]] : tensor<?x17xf32>)
// CHECK:           %[[EPI:.*]] = linalg.generic
// CHECK-SAME:        ins(%[[BIAS]] : tensor<17xf32>) outs(%[[MM]] : tensor<?x17xf32>)
// CHECK:             arith.addf
// CHECK:             arith.maximumf
// CHECK:           tensor.insert_slice %[[EPI]] into %[[ACC]][%[[I]], 0] [%[[SZ]], 17]
func.func @mbr(%a: tensor<67x33xf32>, %b: tensor<33x17xf32>, %bias: tensor<17xf32>) -> tensor<67x17xf32> {
  %mm = tforge.matmul %a, %b : tensor<67x33xf32>, tensor<33x17xf32> -> tensor<67x17xf32>
  %ba = tforge.bias_add %mm, %bias : tensor<67x17xf32>, tensor<17xf32> -> tensor<67x17xf32>
  %r = tforge.relu %ba : tensor<67x17xf32> -> tensor<67x17xf32>
  return %r : tensor<67x17xf32>
}

// -----

// Both parallel loops tiled when N exceeds the tile size.
// CHECK-LABEL: func.func @two_level
// CHECK:         scf.for
// CHECK:           scf.for
// CHECK:             linalg.fill
// CHECK:             linalg.matmul ins(%{{.*}}, %{{.*}} : tensor<?x40xf32>, tensor<40x?xf32>)
// CHECK:             linalg.generic
func.func @two_level(%a: tensor<100x40xf32>, %b: tensor<40x70xf32>, %bias: tensor<70xf32>) -> tensor<100x70xf32> {
  %mm = tforge.matmul %a, %b : tensor<100x40xf32>, tensor<40x70xf32> -> tensor<100x70xf32>
  %ba = tforge.bias_add %mm, %bias : tensor<100x70xf32>, tensor<70xf32> -> tensor<100x70xf32>
  return %ba : tensor<100x70xf32>
}

// -----

// Negative: the epilogue reads its own init (accumulates into %x), so it must
// not be rewritten to write into the matmul tile.
// CHECK-LABEL: func.func @reads_init
// CHECK:         %[[MM:.*]] = linalg.matmul
// CHECK:         linalg.generic
// CHECK-SAME:      ins(%[[MM]] : tensor<32x32xf32>) outs(%{{.*}} : tensor<32x32xf32>)
#id = affine_map<(d0, d1) -> (d0, d1)>
func.func @reads_init(%a: tensor<64x64xf32>, %b: tensor<64x64xf32>, %x: tensor<64x64xf32>) -> tensor<64x64xf32> {
  %zero = arith.constant 0.0 : f32
  %e = tensor.empty() : tensor<64x64xf32>
  %f = linalg.fill ins(%zero : f32) outs(%e : tensor<64x64xf32>) -> tensor<64x64xf32>
  %mm = linalg.matmul ins(%a, %b : tensor<64x64xf32>, tensor<64x64xf32>) outs(%f : tensor<64x64xf32>) -> tensor<64x64xf32>
  %r = linalg.generic {indexing_maps = [#id, #id], iterator_types = ["parallel", "parallel"]}
      ins(%mm : tensor<64x64xf32>) outs(%x : tensor<64x64xf32>) {
  ^bb0(%in: f32, %out: f32):
    %s = arith.addf %in, %out : f32
    linalg.yield %s : f32
  } -> tensor<64x64xf32>
  return %r : tensor<64x64xf32>
}
