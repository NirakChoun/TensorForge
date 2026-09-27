// -----// IR Dump Before OneShotBufferizePass: one-shot-bufferize{allow-return-allocs-from-loops=false allow-unknown-ops=false analysis-fuzzer-seed=0 analysis-heuristic=bottom-up buffer-alignment=64 bufferize-function-boundaries=true check-parallel-regions=true copy-before-write=false  dump-alias-sets=false function-boundary-type-conversion=identity-layout-map must-infer-memory-space=false  print-conflicts=false test-analysis-only=false unknown-type-conversion=fully-dynamic-layout-map use-encoding-for-memory-space=false} //----- //
#map = affine_map<(d0) -> (d0 * 16)>
#map1 = affine_map<(d0, d1) -> (d1)>
#map2 = affine_map<(d0, d1) -> (d0, d1)>
module {
  func.func @entry(%arg0: tensor<1024x1024xf32>, %arg1: tensor<1024x1024xf32>, %arg2: tensor<1024xf32>) -> tensor<1024x1024xf32> {
    %cst = arith.constant 0.000000e+00 : f32
    %0 = tensor.empty() : tensor<1024x1024xf32>
    %1 = scf.forall (%arg3, %arg4) in (64, 64) shared_outs(%arg5 = %0) -> (tensor<1024x1024xf32>) {
      %2 = affine.apply #map(%arg3)
      %3 = affine.apply #map(%arg4)
      %extracted_slice = tensor.extract_slice %arg2[%3] [16] [1] : tensor<1024xf32> to tensor<16xf32>
      %4 = affine.apply #map(%arg3)
      %5 = affine.apply #map(%arg4)
      %extracted_slice_0 = tensor.extract_slice %arg0[%4, 0] [16, 1024] [1, 1] : tensor<1024x1024xf32> to tensor<16x1024xf32>
      %extracted_slice_1 = tensor.extract_slice %arg1[0, %5] [1024, 16] [1, 1] : tensor<1024x1024xf32> to tensor<1024x16xf32>
      %6 = affine.apply #map(%arg3)
      %7 = affine.apply #map(%arg4)
      %extracted_slice_2 = tensor.extract_slice %arg5[%6, %7] [16, 16] [1, 1] : tensor<1024x1024xf32> to tensor<16x16xf32>
      %8 = scf.forall (%arg6, %arg7) in (16, 16) shared_outs(%arg8 = %extracted_slice_2) -> (tensor<16x16xf32>) {
        %extracted_slice_3 = tensor.extract_slice %extracted_slice[%arg7] [1] [1] : tensor<16xf32> to tensor<1xf32>
        %extracted_slice_4 = tensor.extract_slice %extracted_slice_0[%arg6, 0] [1, 1024] [1, 1] : tensor<16x1024xf32> to tensor<1x1024xf32>
        %extracted_slice_5 = tensor.extract_slice %extracted_slice_1[0, %arg7] [1024, 1] [1, 1] : tensor<1024x16xf32> to tensor<1024x1xf32>
        %extracted_slice_6 = tensor.extract_slice %arg8[%arg6, %arg7] [1, 1] [1, 1] : tensor<16x16xf32> to tensor<1x1xf32>
        %9 = linalg.fill ins(%cst : f32) outs(%extracted_slice_6 : tensor<1x1xf32>) -> tensor<1x1xf32>
        %10 = linalg.matmul ins(%extracted_slice_4, %extracted_slice_5 : tensor<1x1024xf32>, tensor<1024x1xf32>) outs(%9 : tensor<1x1xf32>) -> tensor<1x1xf32>
        %11 = linalg.generic {indexing_maps = [#map1, #map2], iterator_types = ["parallel", "parallel"]} ins(%extracted_slice_3 : tensor<1xf32>) outs(%10 : tensor<1x1xf32>) {
        ^bb0(%in: f32, %out: f32):
          %12 = arith.addf %out, %in : f32
          %13 = arith.maximumf %12, %cst : f32
          linalg.yield %13 : f32
        } -> tensor<1x1xf32>
        scf.forall.in_parallel {
          tensor.parallel_insert_slice %11 into %arg8[%arg6, %arg7] [1, 1] [1, 1] : tensor<1x1xf32> into tensor<16x16xf32>
        }
      } {mapping = [#gpu.thread<y>, #gpu.thread<x>]}
      scf.forall.in_parallel {
        tensor.parallel_insert_slice %8 into %arg5[%2, %3] [16, 16] [1, 1] : tensor<16x16xf32> into tensor<1024x1024xf32>
      }
    } {mapping = [#gpu.block<y>, #gpu.block<x>]}
    return %1 : tensor<1024x1024xf32>
  }
}


