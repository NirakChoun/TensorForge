// -----// IR Dump Before OneShotBufferizePass: one-shot-bufferize{allow-return-allocs-from-loops=false allow-unknown-ops=false analysis-fuzzer-seed=0 analysis-heuristic=bottom-up buffer-alignment=64 bufferize-function-boundaries=true check-parallel-regions=true copy-before-write=false  dump-alias-sets=false function-boundary-type-conversion=identity-layout-map must-infer-memory-space=false  print-conflicts=false test-analysis-only=false unknown-type-conversion=fully-dynamic-layout-map use-encoding-for-memory-space=false} //----- //
#map = affine_map<(d0) -> (-d0 + 250, 32)>
#map1 = affine_map<(d0) -> (-d0 + 330, 32)>
#map2 = affine_map<(d0, d1) -> (d1)>
#map3 = affine_map<(d0, d1) -> (d0, d1)>
module {
  func.func @entry(%arg0: tensor<250x170xf32>, %arg1: tensor<170x330xf32>, %arg2: tensor<330xf32>) -> tensor<250x330xf32> {
    %c32 = arith.constant 32 : index
    %c330 = arith.constant 330 : index
    %c250 = arith.constant 250 : index
    %c0 = arith.constant 0 : index
    %cst = arith.constant 0.000000e+00 : f32
    %0 = tensor.empty() : tensor<250x330xf32>
    %1 = scf.for %arg3 = %c0 to %c250 step %c32 iter_args(%arg4 = %0) -> (tensor<250x330xf32>) {
      %2 = scf.for %arg5 = %c0 to %c330 step %c32 iter_args(%arg6 = %arg4) -> (tensor<250x330xf32>) {
        %3 = affine.min #map(%arg3)
        %4 = affine.min #map1(%arg5)
        %extracted_slice = tensor.extract_slice %arg0[%arg3, 0] [%3, 170] [1, 1] : tensor<250x170xf32> to tensor<?x170xf32>
        %extracted_slice_0 = tensor.extract_slice %arg1[0, %arg5] [170, %4] [1, 1] : tensor<170x330xf32> to tensor<170x?xf32>
        %extracted_slice_1 = tensor.extract_slice %arg6[%arg3, %arg5] [%3, %4] [1, 1] : tensor<250x330xf32> to tensor<?x?xf32>
        %5 = tensor.empty(%3, %4) : tensor<?x?xf32>
        %6 = linalg.fill ins(%cst : f32) outs(%extracted_slice_1 : tensor<?x?xf32>) -> tensor<?x?xf32>
        %7 = linalg.matmul ins(%extracted_slice, %extracted_slice_0 : tensor<?x170xf32>, tensor<170x?xf32>) outs(%6 : tensor<?x?xf32>) -> tensor<?x?xf32>
        %extracted_slice_2 = tensor.extract_slice %arg2[%arg5] [%4] [1] : tensor<330xf32> to tensor<?xf32>
        %8 = linalg.generic {indexing_maps = [#map2, #map3], iterator_types = ["parallel", "parallel"]} ins(%extracted_slice_2 : tensor<?xf32>) outs(%7 : tensor<?x?xf32>) {
        ^bb0(%in: f32, %out: f32):
          %9 = arith.addf %out, %in : f32
          %10 = arith.maximumf %9, %cst : f32
          linalg.yield %10 : f32
        } -> tensor<?x?xf32>
        %inserted_slice = tensor.insert_slice %8 into %arg6[%arg3, %arg5] [%3, %4] [1, 1] : tensor<?x?xf32> into tensor<250x330xf32>
        scf.yield %inserted_slice : tensor<250x330xf32>
      }
      scf.yield %2 : tensor<250x330xf32>
    }
    return %1 : tensor<250x330xf32>
  }
}


