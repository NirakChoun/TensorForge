#map = affine_map<(d0, d1) -> (d0, d1)>
#map1 = affine_map<(d0, d1) -> (d1)>
module {
  func.func @entry(%arg0: tensor<250x170xf32>, %arg1: tensor<170x330xf32>, %arg2: tensor<330xf32>) -> tensor<250x330xf32> {
    %cst = arith.constant 0.000000e+00 : f32
    %0 = tensor.empty() : tensor<250x330xf32>
    %1 = linalg.fill ins(%cst : f32) outs(%0 : tensor<250x330xf32>) -> tensor<250x330xf32>
    %2 = linalg.matmul ins(%arg0, %arg1 : tensor<250x170xf32>, tensor<170x330xf32>) outs(%1 : tensor<250x330xf32>) -> tensor<250x330xf32>
    %3 = tensor.empty() : tensor<250x330xf32>
    %4 = linalg.generic {indexing_maps = [#map, #map1, #map], iterator_types = ["parallel", "parallel"]} ins(%2, %arg2 : tensor<250x330xf32>, tensor<330xf32>) outs(%3 : tensor<250x330xf32>) {
    ^bb0(%in: f32, %in_0: f32, %out: f32):
      %7 = arith.addf %in, %in_0 : f32
      linalg.yield %7 : f32
    } -> tensor<250x330xf32>
    %5 = tensor.empty() : tensor<250x330xf32>
    %6 = linalg.generic {indexing_maps = [#map, #map], iterator_types = ["parallel", "parallel"]} ins(%4 : tensor<250x330xf32>) outs(%5 : tensor<250x330xf32>) {
    ^bb0(%in: f32, %out: f32):
      %7 = arith.maximumf %in, %cst : f32
      linalg.yield %7 : f32
    } -> tensor<250x330xf32>
    return %6 : tensor<250x330xf32>
  }
}

