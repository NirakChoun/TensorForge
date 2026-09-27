// -----// IR Dump Before ConvertLinalgToLoopsPass: convert-linalg-to-loops //----- //
#map = affine_map<(d0) -> (-d0 + 250, 32)>
#map1 = affine_map<(d0) -> (-d0 + 330, 32)>
#map2 = affine_map<(d0, d1) -> (d1)>
#map3 = affine_map<(d0, d1) -> (d0, d1)>
module {
  func.func @entry(%arg0: memref<250x170xf32>, %arg1: memref<170x330xf32>, %arg2: memref<330xf32>, %arg3: memref<250x330xf32>) {
    %c32 = arith.constant 32 : index
    %c330 = arith.constant 330 : index
    %c250 = arith.constant 250 : index
    %c0 = arith.constant 0 : index
    %cst = arith.constant 0.000000e+00 : f32
    scf.for %arg4 = %c0 to %c250 step %c32 {
      scf.for %arg5 = %c0 to %c330 step %c32 {
        %0 = affine.min #map(%arg4)
        %1 = affine.min #map1(%arg5)
        %subview = memref.subview %arg0[%arg4, 0] [%0, 170] [1, 1] : memref<250x170xf32> to memref<?x170xf32, strided<[170, 1], offset: ?>>
        %subview_0 = memref.subview %arg1[0, %arg5] [170, %1] [1, 1] : memref<170x330xf32> to memref<170x?xf32, strided<[330, 1], offset: ?>>
        %subview_1 = memref.subview %arg3[%arg4, %arg5] [%0, %1] [1, 1] : memref<250x330xf32> to memref<?x?xf32, strided<[330, 1], offset: ?>>
        linalg.fill ins(%cst : f32) outs(%subview_1 : memref<?x?xf32, strided<[330, 1], offset: ?>>)
        linalg.matmul ins(%subview, %subview_0 : memref<?x170xf32, strided<[170, 1], offset: ?>>, memref<170x?xf32, strided<[330, 1], offset: ?>>) outs(%subview_1 : memref<?x?xf32, strided<[330, 1], offset: ?>>)
        %subview_2 = memref.subview %arg2[%arg5] [%1] [1] : memref<330xf32> to memref<?xf32, strided<[1], offset: ?>>
        linalg.generic {indexing_maps = [#map2, #map3], iterator_types = ["parallel", "parallel"]} ins(%subview_2 : memref<?xf32, strided<[1], offset: ?>>) outs(%subview_1 : memref<?x?xf32, strided<[330, 1], offset: ?>>) {
        ^bb0(%in: f32, %out: f32):
          %2 = arith.addf %out, %in : f32
          %3 = arith.maximumf %2, %cst : f32
          linalg.yield %3 : f32
        }
      }
    }
    return
  }
}


