// -----// IR Dump Before OneShotBufferizePass: one-shot-bufferize{allow-return-allocs-from-loops=false allow-unknown-ops=false analysis-fuzzer-seed=0 analysis-heuristic=bottom-up buffer-alignment=64 bufferize-function-boundaries=true check-parallel-regions=true copy-before-write=false  dump-alias-sets=false function-boundary-type-conversion=identity-layout-map must-infer-memory-space=false  print-conflicts=false test-analysis-only=false unknown-type-conversion=fully-dynamic-layout-map use-encoding-for-memory-space=false} //----- //
#map = affine_map<(d0, d1, d2) -> (d0, d2)>
#map1 = affine_map<(d0, d1, d2) -> (d2, d1)>
#map2 = affine_map<(d0, d1, d2) -> (d0, d1)>
#map3 = affine_map<(d0) -> (0, d0)>
module {
  func.func @entry(%arg0: tensor<250x170xf32>, %arg1: tensor<170x330xf32>, %arg2: tensor<330xf32>) -> tensor<250x330xf32> {
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
    %1 = tensor.empty() : tensor<250x330xf32>
    %2 = scf.for %arg3 = %c0 to %c246 step %c6 iter_args(%arg4 = %1) -> (tensor<250x330xf32>) {
      %12 = scf.for %arg5 = %c0 to %c320 step %c16 iter_args(%arg6 = %arg4) -> (tensor<250x330xf32>) {
        %extracted_slice_16 = tensor.extract_slice %arg0[%arg3, 0] [6, 170] [1, 1] : tensor<250x170xf32> to tensor<6x170xf32>
        %extracted_slice_17 = tensor.extract_slice %arg1[0, %arg5] [170, 16] [1, 1] : tensor<170x330xf32> to tensor<170x16xf32>
        %21 = scf.for %arg7 = %c0 to %c168 step %c4 iter_args(%arg8 = %cst_2) -> (vector<6x16xf32>) {
          %extracted_slice_23 = tensor.extract_slice %extracted_slice_16[0, %arg7] [6, 4] [1, 1] : tensor<6x170xf32> to tensor<6x4xf32>
          %extracted_slice_24 = tensor.extract_slice %extracted_slice_17[%arg7, 0] [4, 16] [1, 1] : tensor<170x16xf32> to tensor<4x16xf32>
          %29 = vector.transfer_read %extracted_slice_23[%c0, %c0], %cst_3 {in_bounds = [true, true]} : tensor<6x4xf32>, vector<6x4xf32>
          %30 = vector.transfer_read %extracted_slice_24[%c0, %c0], %cst_3 {in_bounds = [true, true]} : tensor<4x16xf32>, vector<4x16xf32>
          %31 = vector.contract {indexing_maps = [#map, #map1, #map2], iterator_types = ["parallel", "parallel", "reduction"], kind = #vector.kind<add>} %29, %30, %arg8 : vector<6x4xf32>, vector<4x16xf32> into vector<6x16xf32>
          scf.yield %31 : vector<6x16xf32>
        }
        %extracted_slice_18 = tensor.extract_slice %extracted_slice_16[0, 168] [6, 2] [1, 1] : tensor<6x170xf32> to tensor<6x2xf32>
        %extracted_slice_19 = tensor.extract_slice %extracted_slice_17[168, 0] [2, 16] [1, 1] : tensor<170x16xf32> to tensor<2x16xf32>
        %22 = vector.transfer_read %extracted_slice_18[%c0, %c0], %cst_3 {in_bounds = [true, true]} : tensor<6x2xf32>, vector<6x2xf32>
        %23 = vector.transfer_read %extracted_slice_19[%c0, %c0], %cst_3 {in_bounds = [true, true]} : tensor<2x16xf32>, vector<2x16xf32>
        %24 = vector.contract {indexing_maps = [#map, #map1, #map2], iterator_types = ["parallel", "parallel", "reduction"], kind = #vector.kind<add>} %22, %23, %21 : vector<6x2xf32>, vector<2x16xf32> into vector<6x16xf32>
        %extracted_slice_20 = tensor.extract_slice %arg2[%arg5] [16] [1] : tensor<330xf32> to tensor<16xf32>
        %extracted_slice_21 = tensor.extract_slice %arg6[%arg3, %arg5] [6, 16] [1, 1] : tensor<250x330xf32> to tensor<6x16xf32>
        %25 = vector.transfer_read %extracted_slice_20[%c0], %0 {in_bounds = [true, true], permutation_map = #map3} : tensor<16xf32>, vector<6x16xf32>
        %26 = arith.addf %24, %25 : vector<6x16xf32>
        %27 = arith.maximumf %26, %cst_2 : vector<6x16xf32>
        %28 = vector.transfer_write %27, %extracted_slice_21[%c0, %c0] {in_bounds = [true, true]} : vector<6x16xf32>, tensor<6x16xf32>
        %inserted_slice_22 = tensor.insert_slice %28 into %arg6[%arg3, %arg5] [6, 16] [1, 1] : tensor<6x16xf32> into tensor<250x330xf32>
        scf.yield %inserted_slice_22 : tensor<250x330xf32>
      }
      %extracted_slice_9 = tensor.extract_slice %arg0[%arg3, 0] [6, 170] [1, 1] : tensor<250x170xf32> to tensor<6x170xf32>
      %extracted_slice_10 = tensor.extract_slice %arg1[0, 320] [170, 10] [1, 1] : tensor<170x330xf32> to tensor<170x10xf32>
      %13 = scf.for %arg5 = %c0 to %c168 step %c4 iter_args(%arg6 = %cst_1) -> (vector<6x10xf32>) {
        %extracted_slice_16 = tensor.extract_slice %extracted_slice_9[0, %arg5] [6, 4] [1, 1] : tensor<6x170xf32> to tensor<6x4xf32>
        %extracted_slice_17 = tensor.extract_slice %extracted_slice_10[%arg5, 0] [4, 10] [1, 1] : tensor<170x10xf32> to tensor<4x10xf32>
        %21 = vector.transfer_read %extracted_slice_16[%c0, %c0], %cst_3 {in_bounds = [true, true]} : tensor<6x4xf32>, vector<6x4xf32>
        %22 = vector.transfer_read %extracted_slice_17[%c0, %c0], %cst_3 {in_bounds = [true, true]} : tensor<4x10xf32>, vector<4x10xf32>
        %23 = vector.contract {indexing_maps = [#map, #map1, #map2], iterator_types = ["parallel", "parallel", "reduction"], kind = #vector.kind<add>} %21, %22, %arg6 : vector<6x4xf32>, vector<4x10xf32> into vector<6x10xf32>
        scf.yield %23 : vector<6x10xf32>
      }
      %extracted_slice_11 = tensor.extract_slice %extracted_slice_9[0, 168] [6, 2] [1, 1] : tensor<6x170xf32> to tensor<6x2xf32>
      %extracted_slice_12 = tensor.extract_slice %extracted_slice_10[168, 0] [2, 10] [1, 1] : tensor<170x10xf32> to tensor<2x10xf32>
      %14 = vector.transfer_read %extracted_slice_11[%c0, %c0], %cst_3 {in_bounds = [true, true]} : tensor<6x2xf32>, vector<6x2xf32>
      %15 = vector.transfer_read %extracted_slice_12[%c0, %c0], %cst_3 {in_bounds = [true, true]} : tensor<2x10xf32>, vector<2x10xf32>
      %16 = vector.contract {indexing_maps = [#map, #map1, #map2], iterator_types = ["parallel", "parallel", "reduction"], kind = #vector.kind<add>} %14, %15, %13 : vector<6x2xf32>, vector<2x10xf32> into vector<6x10xf32>
      %extracted_slice_13 = tensor.extract_slice %arg2[320] [10] [1] : tensor<330xf32> to tensor<10xf32>
      %extracted_slice_14 = tensor.extract_slice %12[%arg3, 320] [6, 10] [1, 1] : tensor<250x330xf32> to tensor<6x10xf32>
      %17 = vector.transfer_read %extracted_slice_13[%c0], %0 {in_bounds = [true, true], permutation_map = #map3} : tensor<10xf32>, vector<6x10xf32>
      %18 = arith.addf %16, %17 : vector<6x10xf32>
      %19 = arith.maximumf %18, %cst_1 : vector<6x10xf32>
      %20 = vector.transfer_write %19, %extracted_slice_14[%c0, %c0] {in_bounds = [true, true]} : vector<6x10xf32>, tensor<6x10xf32>
      %inserted_slice_15 = tensor.insert_slice %20 into %12[%arg3, 320] [6, 10] [1, 1] : tensor<6x10xf32> into tensor<250x330xf32>
      scf.yield %inserted_slice_15 : tensor<250x330xf32>
    }
    %3 = scf.for %arg3 = %c0 to %c320 step %c16 iter_args(%arg4 = %2) -> (tensor<250x330xf32>) {
      %extracted_slice_9 = tensor.extract_slice %arg0[246, 0] [4, 170] [1, 1] : tensor<250x170xf32> to tensor<4x170xf32>
      %extracted_slice_10 = tensor.extract_slice %arg1[0, %arg3] [170, 16] [1, 1] : tensor<170x330xf32> to tensor<170x16xf32>
      %12 = scf.for %arg5 = %c0 to %c168 step %c4 iter_args(%arg6 = %cst_0) -> (vector<4x16xf32>) {
        %extracted_slice_16 = tensor.extract_slice %extracted_slice_9[0, %arg5] [4, 4] [1, 1] : tensor<4x170xf32> to tensor<4x4xf32>
        %extracted_slice_17 = tensor.extract_slice %extracted_slice_10[%arg5, 0] [4, 16] [1, 1] : tensor<170x16xf32> to tensor<4x16xf32>
        %20 = vector.transfer_read %extracted_slice_16[%c0, %c0], %cst_3 {in_bounds = [true, true]} : tensor<4x4xf32>, vector<4x4xf32>
        %21 = vector.transfer_read %extracted_slice_17[%c0, %c0], %cst_3 {in_bounds = [true, true]} : tensor<4x16xf32>, vector<4x16xf32>
        %22 = vector.contract {indexing_maps = [#map, #map1, #map2], iterator_types = ["parallel", "parallel", "reduction"], kind = #vector.kind<add>} %20, %21, %arg6 : vector<4x4xf32>, vector<4x16xf32> into vector<4x16xf32>
        scf.yield %22 : vector<4x16xf32>
      }
      %extracted_slice_11 = tensor.extract_slice %extracted_slice_9[0, 168] [4, 2] [1, 1] : tensor<4x170xf32> to tensor<4x2xf32>
      %extracted_slice_12 = tensor.extract_slice %extracted_slice_10[168, 0] [2, 16] [1, 1] : tensor<170x16xf32> to tensor<2x16xf32>
      %13 = vector.transfer_read %extracted_slice_11[%c0, %c0], %cst_3 {in_bounds = [true, true]} : tensor<4x2xf32>, vector<4x2xf32>
      %14 = vector.transfer_read %extracted_slice_12[%c0, %c0], %cst_3 {in_bounds = [true, true]} : tensor<2x16xf32>, vector<2x16xf32>
      %15 = vector.contract {indexing_maps = [#map, #map1, #map2], iterator_types = ["parallel", "parallel", "reduction"], kind = #vector.kind<add>} %13, %14, %12 : vector<4x2xf32>, vector<2x16xf32> into vector<4x16xf32>
      %extracted_slice_13 = tensor.extract_slice %arg2[%arg3] [16] [1] : tensor<330xf32> to tensor<16xf32>
      %extracted_slice_14 = tensor.extract_slice %arg4[246, %arg3] [4, 16] [1, 1] : tensor<250x330xf32> to tensor<4x16xf32>
      %16 = vector.transfer_read %extracted_slice_13[%c0], %0 {in_bounds = [true, true], permutation_map = #map3} : tensor<16xf32>, vector<4x16xf32>
      %17 = arith.addf %15, %16 : vector<4x16xf32>
      %18 = arith.maximumf %17, %cst_0 : vector<4x16xf32>
      %19 = vector.transfer_write %18, %extracted_slice_14[%c0, %c0] {in_bounds = [true, true]} : vector<4x16xf32>, tensor<4x16xf32>
      %inserted_slice_15 = tensor.insert_slice %19 into %arg4[246, %arg3] [4, 16] [1, 1] : tensor<4x16xf32> into tensor<250x330xf32>
      scf.yield %inserted_slice_15 : tensor<250x330xf32>
    }
    %extracted_slice = tensor.extract_slice %arg0[246, 0] [4, 170] [1, 1] : tensor<250x170xf32> to tensor<4x170xf32>
    %extracted_slice_4 = tensor.extract_slice %arg1[0, 320] [170, 10] [1, 1] : tensor<170x330xf32> to tensor<170x10xf32>
    %4 = scf.for %arg3 = %c0 to %c168 step %c4 iter_args(%arg4 = %cst) -> (vector<4x10xf32>) {
      %extracted_slice_9 = tensor.extract_slice %extracted_slice[0, %arg3] [4, 4] [1, 1] : tensor<4x170xf32> to tensor<4x4xf32>
      %extracted_slice_10 = tensor.extract_slice %extracted_slice_4[%arg3, 0] [4, 10] [1, 1] : tensor<170x10xf32> to tensor<4x10xf32>
      %12 = vector.transfer_read %extracted_slice_9[%c0, %c0], %cst_3 {in_bounds = [true, true]} : tensor<4x4xf32>, vector<4x4xf32>
      %13 = vector.transfer_read %extracted_slice_10[%c0, %c0], %cst_3 {in_bounds = [true, true]} : tensor<4x10xf32>, vector<4x10xf32>
      %14 = vector.contract {indexing_maps = [#map, #map1, #map2], iterator_types = ["parallel", "parallel", "reduction"], kind = #vector.kind<add>} %12, %13, %arg4 : vector<4x4xf32>, vector<4x10xf32> into vector<4x10xf32>
      scf.yield %14 : vector<4x10xf32>
    }
    %extracted_slice_5 = tensor.extract_slice %extracted_slice[0, 168] [4, 2] [1, 1] : tensor<4x170xf32> to tensor<4x2xf32>
    %extracted_slice_6 = tensor.extract_slice %extracted_slice_4[168, 0] [2, 10] [1, 1] : tensor<170x10xf32> to tensor<2x10xf32>
    %5 = vector.transfer_read %extracted_slice_5[%c0, %c0], %cst_3 {in_bounds = [true, true]} : tensor<4x2xf32>, vector<4x2xf32>
    %6 = vector.transfer_read %extracted_slice_6[%c0, %c0], %cst_3 {in_bounds = [true, true]} : tensor<2x10xf32>, vector<2x10xf32>
    %7 = vector.contract {indexing_maps = [#map, #map1, #map2], iterator_types = ["parallel", "parallel", "reduction"], kind = #vector.kind<add>} %5, %6, %4 : vector<4x2xf32>, vector<2x10xf32> into vector<4x10xf32>
    %extracted_slice_7 = tensor.extract_slice %arg2[320] [10] [1] : tensor<330xf32> to tensor<10xf32>
    %extracted_slice_8 = tensor.extract_slice %3[246, 320] [4, 10] [1, 1] : tensor<250x330xf32> to tensor<4x10xf32>
    %8 = vector.transfer_read %extracted_slice_7[%c0], %0 {in_bounds = [true, true], permutation_map = #map3} : tensor<10xf32>, vector<4x10xf32>
    %9 = arith.addf %7, %8 : vector<4x10xf32>
    %10 = arith.maximumf %9, %cst : vector<4x10xf32>
    %11 = vector.transfer_write %10, %extracted_slice_8[%c0, %c0] {in_bounds = [true, true]} : vector<4x10xf32>, tensor<4x10xf32>
    %inserted_slice = tensor.insert_slice %11 into %3[246, 320] [4, 10] [1, 1] : tensor<4x10xf32> into tensor<250x330xf32>
    return %inserted_slice : tensor<250x330xf32>
  }
}


