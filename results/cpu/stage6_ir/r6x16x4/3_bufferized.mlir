// -----// IR Dump Before ConvertLinalgToLoopsPass: convert-linalg-to-loops //----- //
#map = affine_map<(d0, d1, d2) -> (d0, d2)>
#map1 = affine_map<(d0, d1, d2) -> (d2, d1)>
#map2 = affine_map<(d0, d1, d2) -> (d0, d1)>
#map3 = affine_map<(d0) -> (0, d0)>
module {
  func.func @entry(%arg0: memref<250x170xf32>, %arg1: memref<170x330xf32>, %arg2: memref<330xf32>, %arg3: memref<250x330xf32>) {
    %cst = arith.constant dense<0.000000e+00> : vector<4x10xf32>
    %cst_0 = arith.constant dense<0.000000e+00> : vector<4x16xf32>
    %cst_1 = arith.constant dense<0.000000e+00> : vector<6x10xf32>
    %cst_2 = arith.constant dense<0.000000e+00> : vector<6x16xf32>
    %0 = ub.poison : f32
    %c168 = arith.constant 168 : index
    %c4 = arith.constant 4 : index
    %c320 = arith.constant 320 : index
    %c246 = arith.constant 246 : index
    %c16 = arith.constant 16 : index
    %c6 = arith.constant 6 : index
    %c0 = arith.constant 0 : index
    %cst_3 = arith.constant 0.000000e+00 : f32
    scf.for %arg4 = %c0 to %c246 step %c6 {
      scf.for %arg5 = %c0 to %c320 step %c16 {
        %subview_15 = memref.subview %arg0[%arg4, 0] [6, 170] [1, 1] : memref<250x170xf32> to memref<6x170xf32, strided<[170, 1], offset: ?>>
        %subview_16 = memref.subview %arg1[0, %arg5] [170, 16] [1, 1] : memref<170x330xf32> to memref<170x16xf32, strided<[330, 1], offset: ?>>
        %15 = scf.for %arg6 = %c0 to %c168 step %c4 iter_args(%arg7 = %cst_2) -> (vector<6x16xf32>) {
          %subview_21 = memref.subview %subview_15[0, %arg6] [6, 4] [1, 1] : memref<6x170xf32, strided<[170, 1], offset: ?>> to memref<6x4xf32, strided<[170, 1], offset: ?>>
          %subview_22 = memref.subview %subview_16[%arg6, 0] [4, 16] [1, 1] : memref<170x16xf32, strided<[330, 1], offset: ?>> to memref<4x16xf32, strided<[330, 1], offset: ?>>
          %22 = vector.transfer_read %subview_21[%c0, %c0], %cst_3 {in_bounds = [true, true]} : memref<6x4xf32, strided<[170, 1], offset: ?>>, vector<6x4xf32>
          %23 = vector.transfer_read %subview_22[%c0, %c0], %cst_3 {in_bounds = [true, true]} : memref<4x16xf32, strided<[330, 1], offset: ?>>, vector<4x16xf32>
          %24 = vector.contract {indexing_maps = [#map, #map1, #map2], iterator_types = ["parallel", "parallel", "reduction"], kind = #vector.kind<add>} %22, %23, %arg7 : vector<6x4xf32>, vector<4x16xf32> into vector<6x16xf32>
          scf.yield %24 : vector<6x16xf32>
        }
        %subview_17 = memref.subview %subview_15[0, 168] [6, 2] [1, 1] : memref<6x170xf32, strided<[170, 1], offset: ?>> to memref<6x2xf32, strided<[170, 1], offset: ?>>
        %subview_18 = memref.subview %subview_16[168, 0] [2, 16] [1, 1] : memref<170x16xf32, strided<[330, 1], offset: ?>> to memref<2x16xf32, strided<[330, 1], offset: ?>>
        %16 = vector.transfer_read %subview_17[%c0, %c0], %cst_3 {in_bounds = [true, true]} : memref<6x2xf32, strided<[170, 1], offset: ?>>, vector<6x2xf32>
        %17 = vector.transfer_read %subview_18[%c0, %c0], %cst_3 {in_bounds = [true, true]} : memref<2x16xf32, strided<[330, 1], offset: ?>>, vector<2x16xf32>
        %18 = vector.contract {indexing_maps = [#map, #map1, #map2], iterator_types = ["parallel", "parallel", "reduction"], kind = #vector.kind<add>} %16, %17, %15 : vector<6x2xf32>, vector<2x16xf32> into vector<6x16xf32>
        %subview_19 = memref.subview %arg2[%arg5] [16] [1] : memref<330xf32> to memref<16xf32, strided<[1], offset: ?>>
        %subview_20 = memref.subview %arg3[%arg4, %arg5] [6, 16] [1, 1] : memref<250x330xf32> to memref<6x16xf32, strided<[330, 1], offset: ?>>
        %19 = vector.transfer_read %subview_19[%c0], %0 {in_bounds = [true, true], permutation_map = #map3} : memref<16xf32, strided<[1], offset: ?>>, vector<6x16xf32>
        %20 = arith.addf %18, %19 : vector<6x16xf32>
        %21 = arith.maximumf %20, %cst_2 : vector<6x16xf32>
        vector.transfer_write %21, %subview_20[%c0, %c0] {in_bounds = [true, true]} : vector<6x16xf32>, memref<6x16xf32, strided<[330, 1], offset: ?>>
      }
      %subview_9 = memref.subview %arg0[%arg4, 0] [6, 170] [1, 1] : memref<250x170xf32> to memref<6x170xf32, strided<[170, 1], offset: ?>>
      %subview_10 = memref.subview %arg1[0, 320] [170, 10] [1, 1] : memref<170x330xf32> to memref<170x10xf32, strided<[330, 1], offset: 320>>
      %8 = scf.for %arg5 = %c0 to %c168 step %c4 iter_args(%arg6 = %cst_1) -> (vector<6x10xf32>) {
        %subview_15 = memref.subview %subview_9[0, %arg5] [6, 4] [1, 1] : memref<6x170xf32, strided<[170, 1], offset: ?>> to memref<6x4xf32, strided<[170, 1], offset: ?>>
        %subview_16 = memref.subview %subview_10[%arg5, 0] [4, 10] [1, 1] : memref<170x10xf32, strided<[330, 1], offset: 320>> to memref<4x10xf32, strided<[330, 1], offset: ?>>
        %15 = vector.transfer_read %subview_15[%c0, %c0], %cst_3 {in_bounds = [true, true]} : memref<6x4xf32, strided<[170, 1], offset: ?>>, vector<6x4xf32>
        %16 = vector.transfer_read %subview_16[%c0, %c0], %cst_3 {in_bounds = [true, true]} : memref<4x10xf32, strided<[330, 1], offset: ?>>, vector<4x10xf32>
        %17 = vector.contract {indexing_maps = [#map, #map1, #map2], iterator_types = ["parallel", "parallel", "reduction"], kind = #vector.kind<add>} %15, %16, %arg6 : vector<6x4xf32>, vector<4x10xf32> into vector<6x10xf32>
        scf.yield %17 : vector<6x10xf32>
      }
      %subview_11 = memref.subview %subview_9[0, 168] [6, 2] [1, 1] : memref<6x170xf32, strided<[170, 1], offset: ?>> to memref<6x2xf32, strided<[170, 1], offset: ?>>
      %subview_12 = memref.subview %subview_10[168, 0] [2, 10] [1, 1] : memref<170x10xf32, strided<[330, 1], offset: 320>> to memref<2x10xf32, strided<[330, 1], offset: 55760>>
      %9 = vector.transfer_read %subview_11[%c0, %c0], %cst_3 {in_bounds = [true, true]} : memref<6x2xf32, strided<[170, 1], offset: ?>>, vector<6x2xf32>
      %10 = vector.transfer_read %subview_12[%c0, %c0], %cst_3 {in_bounds = [true, true]} : memref<2x10xf32, strided<[330, 1], offset: 55760>>, vector<2x10xf32>
      %11 = vector.contract {indexing_maps = [#map, #map1, #map2], iterator_types = ["parallel", "parallel", "reduction"], kind = #vector.kind<add>} %9, %10, %8 : vector<6x2xf32>, vector<2x10xf32> into vector<6x10xf32>
      %subview_13 = memref.subview %arg2[320] [10] [1] : memref<330xf32> to memref<10xf32, strided<[1], offset: 320>>
      %subview_14 = memref.subview %arg3[%arg4, 320] [6, 10] [1, 1] : memref<250x330xf32> to memref<6x10xf32, strided<[330, 1], offset: ?>>
      %12 = vector.transfer_read %subview_13[%c0], %0 {in_bounds = [true, true], permutation_map = #map3} : memref<10xf32, strided<[1], offset: 320>>, vector<6x10xf32>
      %13 = arith.addf %11, %12 : vector<6x10xf32>
      %14 = arith.maximumf %13, %cst_1 : vector<6x10xf32>
      vector.transfer_write %14, %subview_14[%c0, %c0] {in_bounds = [true, true]} : vector<6x10xf32>, memref<6x10xf32, strided<[330, 1], offset: ?>>
    }
    scf.for %arg4 = %c0 to %c320 step %c16 {
      %subview_9 = memref.subview %arg0[246, 0] [4, 170] [1, 1] : memref<250x170xf32> to memref<4x170xf32, strided<[170, 1], offset: 41820>>
      %subview_10 = memref.subview %arg1[0, %arg4] [170, 16] [1, 1] : memref<170x330xf32> to memref<170x16xf32, strided<[330, 1], offset: ?>>
      %8 = scf.for %arg5 = %c0 to %c168 step %c4 iter_args(%arg6 = %cst_0) -> (vector<4x16xf32>) {
        %subview_15 = memref.subview %subview_9[0, %arg5] [4, 4] [1, 1] : memref<4x170xf32, strided<[170, 1], offset: 41820>> to memref<4x4xf32, strided<[170, 1], offset: ?>>
        %subview_16 = memref.subview %subview_10[%arg5, 0] [4, 16] [1, 1] : memref<170x16xf32, strided<[330, 1], offset: ?>> to memref<4x16xf32, strided<[330, 1], offset: ?>>
        %15 = vector.transfer_read %subview_15[%c0, %c0], %cst_3 {in_bounds = [true, true]} : memref<4x4xf32, strided<[170, 1], offset: ?>>, vector<4x4xf32>
        %16 = vector.transfer_read %subview_16[%c0, %c0], %cst_3 {in_bounds = [true, true]} : memref<4x16xf32, strided<[330, 1], offset: ?>>, vector<4x16xf32>
        %17 = vector.contract {indexing_maps = [#map, #map1, #map2], iterator_types = ["parallel", "parallel", "reduction"], kind = #vector.kind<add>} %15, %16, %arg6 : vector<4x4xf32>, vector<4x16xf32> into vector<4x16xf32>
        scf.yield %17 : vector<4x16xf32>
      }
      %subview_11 = memref.subview %subview_9[0, 168] [4, 2] [1, 1] : memref<4x170xf32, strided<[170, 1], offset: 41820>> to memref<4x2xf32, strided<[170, 1], offset: 41988>>
      %subview_12 = memref.subview %subview_10[168, 0] [2, 16] [1, 1] : memref<170x16xf32, strided<[330, 1], offset: ?>> to memref<2x16xf32, strided<[330, 1], offset: ?>>
      %9 = vector.transfer_read %subview_11[%c0, %c0], %cst_3 {in_bounds = [true, true]} : memref<4x2xf32, strided<[170, 1], offset: 41988>>, vector<4x2xf32>
      %10 = vector.transfer_read %subview_12[%c0, %c0], %cst_3 {in_bounds = [true, true]} : memref<2x16xf32, strided<[330, 1], offset: ?>>, vector<2x16xf32>
      %11 = vector.contract {indexing_maps = [#map, #map1, #map2], iterator_types = ["parallel", "parallel", "reduction"], kind = #vector.kind<add>} %9, %10, %8 : vector<4x2xf32>, vector<2x16xf32> into vector<4x16xf32>
      %subview_13 = memref.subview %arg2[%arg4] [16] [1] : memref<330xf32> to memref<16xf32, strided<[1], offset: ?>>
      %subview_14 = memref.subview %arg3[246, %arg4] [4, 16] [1, 1] : memref<250x330xf32> to memref<4x16xf32, strided<[330, 1], offset: ?>>
      %12 = vector.transfer_read %subview_13[%c0], %0 {in_bounds = [true, true], permutation_map = #map3} : memref<16xf32, strided<[1], offset: ?>>, vector<4x16xf32>
      %13 = arith.addf %11, %12 : vector<4x16xf32>
      %14 = arith.maximumf %13, %cst_0 : vector<4x16xf32>
      vector.transfer_write %14, %subview_14[%c0, %c0] {in_bounds = [true, true]} : vector<4x16xf32>, memref<4x16xf32, strided<[330, 1], offset: ?>>
    }
    %subview = memref.subview %arg0[246, 0] [4, 170] [1, 1] : memref<250x170xf32> to memref<4x170xf32, strided<[170, 1], offset: 41820>>
    %subview_4 = memref.subview %arg1[0, 320] [170, 10] [1, 1] : memref<170x330xf32> to memref<170x10xf32, strided<[330, 1], offset: 320>>
    %1 = scf.for %arg4 = %c0 to %c168 step %c4 iter_args(%arg5 = %cst) -> (vector<4x10xf32>) {
      %subview_9 = memref.subview %subview[0, %arg4] [4, 4] [1, 1] : memref<4x170xf32, strided<[170, 1], offset: 41820>> to memref<4x4xf32, strided<[170, 1], offset: ?>>
      %subview_10 = memref.subview %subview_4[%arg4, 0] [4, 10] [1, 1] : memref<170x10xf32, strided<[330, 1], offset: 320>> to memref<4x10xf32, strided<[330, 1], offset: ?>>
      %8 = vector.transfer_read %subview_9[%c0, %c0], %cst_3 {in_bounds = [true, true]} : memref<4x4xf32, strided<[170, 1], offset: ?>>, vector<4x4xf32>
      %9 = vector.transfer_read %subview_10[%c0, %c0], %cst_3 {in_bounds = [true, true]} : memref<4x10xf32, strided<[330, 1], offset: ?>>, vector<4x10xf32>
      %10 = vector.contract {indexing_maps = [#map, #map1, #map2], iterator_types = ["parallel", "parallel", "reduction"], kind = #vector.kind<add>} %8, %9, %arg5 : vector<4x4xf32>, vector<4x10xf32> into vector<4x10xf32>
      scf.yield %10 : vector<4x10xf32>
    }
    %subview_5 = memref.subview %subview[0, 168] [4, 2] [1, 1] : memref<4x170xf32, strided<[170, 1], offset: 41820>> to memref<4x2xf32, strided<[170, 1], offset: 41988>>
    %subview_6 = memref.subview %subview_4[168, 0] [2, 10] [1, 1] : memref<170x10xf32, strided<[330, 1], offset: 320>> to memref<2x10xf32, strided<[330, 1], offset: 55760>>
    %2 = vector.transfer_read %subview_5[%c0, %c0], %cst_3 {in_bounds = [true, true]} : memref<4x2xf32, strided<[170, 1], offset: 41988>>, vector<4x2xf32>
    %3 = vector.transfer_read %subview_6[%c0, %c0], %cst_3 {in_bounds = [true, true]} : memref<2x10xf32, strided<[330, 1], offset: 55760>>, vector<2x10xf32>
    %4 = vector.contract {indexing_maps = [#map, #map1, #map2], iterator_types = ["parallel", "parallel", "reduction"], kind = #vector.kind<add>} %2, %3, %1 : vector<4x2xf32>, vector<2x10xf32> into vector<4x10xf32>
    %subview_7 = memref.subview %arg2[320] [10] [1] : memref<330xf32> to memref<10xf32, strided<[1], offset: 320>>
    %subview_8 = memref.subview %arg3[246, 320] [4, 10] [1, 1] : memref<250x330xf32> to memref<4x10xf32, strided<[330, 1], offset: 81500>>
    %5 = vector.transfer_read %subview_7[%c0], %0 {in_bounds = [true, true], permutation_map = #map3} : memref<10xf32, strided<[1], offset: 320>>, vector<4x10xf32>
    %6 = arith.addf %4, %5 : vector<4x10xf32>
    %7 = arith.maximumf %6, %cst : vector<4x10xf32>
    vector.transfer_write %7, %subview_8[%c0, %c0] {in_bounds = [true, true]} : vector<4x10xf32>, memref<4x10xf32, strided<[330, 1], offset: 81500>>
    return
  }
}


