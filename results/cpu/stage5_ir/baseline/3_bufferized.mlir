// -----// IR Dump Before ConvertLinalgToLoopsPass: convert-linalg-to-loops //----- //
#map = affine_map<(d0, d1) -> (d0, d1)>
#map1 = affine_map<(d0, d1) -> (d1)>
module {
  func.func @entry(%arg0: memref<250x170xf32>, %arg1: memref<170x330xf32>, %arg2: memref<330xf32>, %arg3: memref<250x330xf32>) {
    %cst = arith.constant 0.000000e+00 : f32
    %alloc = memref.alloc() {alignment = 64 : i64} : memref<250x330xf32>
    linalg.fill ins(%cst : f32) outs(%alloc : memref<250x330xf32>)
    linalg.matmul ins(%arg0, %arg1 : memref<250x170xf32>, memref<170x330xf32>) outs(%alloc : memref<250x330xf32>)
    %alloc_0 = memref.alloc() {alignment = 64 : i64} : memref<250x330xf32>
    linalg.generic {indexing_maps = [#map, #map1, #map], iterator_types = ["parallel", "parallel"]} ins(%alloc, %arg2 : memref<250x330xf32>, memref<330xf32>) outs(%alloc_0 : memref<250x330xf32>) {
    ^bb0(%in: f32, %in_1: f32, %out: f32):
      %0 = arith.addf %in, %in_1 : f32
      linalg.yield %0 : f32
    }
    linalg.generic {indexing_maps = [#map, #map], iterator_types = ["parallel", "parallel"]} ins(%alloc_0 : memref<250x330xf32>) outs(%arg3 : memref<250x330xf32>) {
    ^bb0(%in: f32, %out: f32):
      %0 = arith.maximumf %in, %cst : f32
      linalg.yield %0 : f32
    }
    memref.dealloc %alloc : memref<250x330xf32>
    memref.dealloc %alloc_0 : memref<250x330xf32>
    return
  }
}


