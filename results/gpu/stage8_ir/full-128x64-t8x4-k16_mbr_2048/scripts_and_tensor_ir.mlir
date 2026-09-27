// tforge transform script
module attributes {transform.with_named_sequence} {
transform.named_sequence @__transform_main(%arg0: !transform.any_op) {
  %root = transform.structured.match attributes{tforge.root} in %arg0 : (!transform.any_op) -> !transform.any_op
  %t0, %blk0 = transform.structured.tile_using_forall %root tile_sizes [128, 64] (mapping = [#gpu.block<y>, #gpu.block<x>]) : (!transform.any_op) -> (!transform.any_op, !transform.any_op)
  %p0 = transform.structured.match ops{["linalg.matmul"]} in %arg0 : (!transform.any_op) -> !transform.any_op
  %pb0, %blk1 = transform.structured.fuse_into_containing_op %p0 into %blk0 : (!transform.any_op, !transform.any_op) -> (!transform.any_op, !transform.any_op)
  %p1 = transform.structured.match ops{["linalg.fill"]} in %arg0 : (!transform.any_op) -> !transform.any_op
  %pb1, %blk2 = transform.structured.fuse_into_containing_op %p1 into %blk1 : (!transform.any_op, !transform.any_op) -> (!transform.any_op, !transform.any_op)
  %mk, %kloop = transform.structured.tile_using_for %pb0 tile_sizes [0, 0, 16] : (!transform.any_op) -> (!transform.any_op, !transform.any_op)
  transform.annotate %mk "tforge.kmatmul" : !transform.any_op
  transform.yield
}
}

// tforge transform script
module attributes {transform.with_named_sequence} {
transform.named_sequence @__transform_main(%arg0: !transform.any_op) {
  %ca = transform.structured.match attributes{tforge.copy_a} in %arg0 : (!transform.any_op) -> !transform.any_op
  %fca, %tca = transform.structured.gpu.map_copy_to_threads %ca total_num_threads = 256 desired_bit_alignment = 128 : (!transform.any_op) -> (!transform.any_op, !transform.any_op)
  %cb = transform.structured.match attributes{tforge.copy_b} in %arg0 : (!transform.any_op) -> !transform.any_op
  %fcb, %tcb = transform.structured.gpu.map_copy_to_threads %cb total_num_threads = 256 desired_bit_alignment = 128 : (!transform.any_op) -> (!transform.any_op, !transform.any_op)
  %kmm = transform.structured.match attributes{tforge.kmatmul} in %arg0 : (!transform.any_op) -> !transform.any_op
  %mm_t, %mm_f = transform.structured.tile_using_forall %kmm num_threads [16, 16] (mapping = [#gpu.thread<y>, #gpu.thread<x>]) : (!transform.any_op) -> (!transform.any_op, !transform.any_op)
  %fill = transform.structured.match ops{["linalg.fill"]} in %arg0 : (!transform.any_op) -> !transform.any_op
  %fill_t, %fill_f = transform.structured.tile_using_forall %fill num_threads [16, 16] (mapping = [#gpu.thread<y>, #gpu.thread<x>]) : (!transform.any_op) -> (!transform.any_op, !transform.any_op)
  %epi = transform.structured.match attributes{tforge.root} in %arg0 : (!transform.any_op) -> !transform.any_op
  %epi_t, %epi_f = transform.structured.tile_using_forall %epi num_threads [16, 16] (mapping = [#gpu.thread<y>, #gpu.thread<x>]) : (!transform.any_op) -> (!transform.any_op, !transform.any_op)
  transform.yield
}
}

// -----// IR Dump Before OneShotBufferizePass: one-shot-bufferize{allow-return-allocs-from-loops=false allow-unknown-ops=false analysis-fuzzer-seed=0 analysis-heuristic=bottom-up buffer-alignment=64 bufferize-function-boundaries=true check-parallel-regions=true copy-before-write=false  dump-alias-sets=false function-boundary-type-conversion=identity-layout-map must-infer-memory-space=false  print-conflicts=false test-analysis-only=false unknown-type-conversion=fully-dynamic-layout-map use-encoding-for-memory-space=false} //----- //
#map = affine_map<(d0) -> (d0 * 128)>
#map1 = affine_map<(d0) -> (d0 * 64)>
#map2 = affine_map<(d0) -> (d0 * 8)>
#map3 = affine_map<(d0) -> (d0 * 4)>
#map4 = affine_map<(d0) -> (d0 * 2)>
#map5 = affine_map<(d0, d1, d2) -> (d0, d2)>
#map6 = affine_map<(d0, d1, d2) -> (d2, d1)>
#map7 = affine_map<(d0, d1, d2) -> (d0, d1)>
#map8 = affine_map<(d0) -> (0, d0)>
module {
  func.func @entry(%arg0: tensor<2048x2048xf32>, %arg1: tensor<2048x2048xf32>, %arg2: tensor<2048xf32>) -> tensor<2048x2048xf32> {
    %cst = arith.constant dense<0.000000e+00> : vector<8x4xf32>
    %0 = ub.poison : f32
    %c16 = arith.constant 16 : index
    %c2048 = arith.constant 2048 : index
    %c0 = arith.constant 0 : index
    %cst_0 = arith.constant 0.000000e+00 : f32
    %1 = tensor.empty() : tensor<2048x2048xf32>
    %2 = scf.forall (%arg3, %arg4) in (16, 32) shared_outs(%arg5 = %1) -> (tensor<2048x2048xf32>) {
      %3 = affine.apply #map(%arg3)
      %4 = affine.apply #map1(%arg4)
      %extracted_slice = tensor.extract_slice %arg2[%4] [64] [1] : tensor<2048xf32> to tensor<64xf32>
      %5 = affine.apply #map(%arg3)
      %6 = affine.apply #map1(%arg4)
      %extracted_slice_1 = tensor.extract_slice %arg0[%5, 0] [128, 2048] [1, 1] : tensor<2048x2048xf32> to tensor<128x2048xf32>
      %extracted_slice_2 = tensor.extract_slice %arg1[0, %6] [2048, 64] [1, 1] : tensor<2048x2048xf32> to tensor<2048x64xf32>
      %7 = affine.apply #map(%arg3)
      %8 = affine.apply #map1(%arg4)
      %extracted_slice_3 = tensor.extract_slice %arg5[%7, %8] [128, 64] [1, 1] : tensor<2048x2048xf32> to tensor<128x64xf32>
      %9 = scf.forall (%arg6, %arg7) in (16, 16) shared_outs(%arg8 = %extracted_slice_3) -> (tensor<128x64xf32>) {
        %12 = affine.apply #map2(%arg6)
        %13 = affine.apply #map3(%arg7)
        %extracted_slice_4 = tensor.extract_slice %arg8[%12, %13] [8, 4] [1, 1] : tensor<128x64xf32> to tensor<8x4xf32>
        %14 = vector.transfer_write %cst, %extracted_slice_4[%c0, %c0] {in_bounds = [true, true]} : vector<8x4xf32>, tensor<8x4xf32>
        %15 = affine.apply #map2(%arg6)
        %16 = affine.apply #map3(%arg7)
        scf.forall.in_parallel {
          tensor.parallel_insert_slice %14 into %arg8[%15, %16] [8, 4] [1, 1] : tensor<8x4xf32> into tensor<128x64xf32>
        }
      } {mapping = [#gpu.thread<y>, #gpu.thread<x>]}
      %10 = scf.for %arg6 = %c0 to %c2048 step %c16 iter_args(%arg7 = %9) -> (tensor<128x64xf32>) {
        %extracted_slice_4 = tensor.extract_slice %extracted_slice_1[0, %arg6] [128, 16] [1, 1] : tensor<128x2048xf32> to tensor<128x16xf32>
        %extracted_slice_5 = tensor.extract_slice %extracted_slice_2[%arg6, 0] [16, 64] [1, 1] : tensor<2048x64xf32> to tensor<16x64xf32>
        %12 = bufferization.alloc_tensor() {memory_space = #gpu.address_space<workgroup>} : tensor<128x16xf32>
        %13 = scf.forall (%arg8, %arg9) in (64, 4) shared_outs(%arg10 = %12) -> (tensor<128x16xf32>) {
          %17 = affine.apply #map4(%arg8)
          %18 = affine.apply #map3(%arg9)
          %extracted_slice_6 = tensor.extract_slice %extracted_slice_4[%17, %18] [2, 4] [1, 1] : tensor<128x16xf32> to tensor<2x4xf32>
          %19 = affine.apply #map4(%arg8)
          %20 = affine.apply #map3(%arg9)
          scf.forall.in_parallel {
            tensor.parallel_insert_slice %extracted_slice_6 into %arg10[%19, %20] [2, 4] [1, 1] : tensor<2x4xf32> into tensor<128x16xf32>
          }
        } {mapping = [#gpu.thread<linear_dim_1>, #gpu.thread<linear_dim_0>]}
        %14 = bufferization.alloc_tensor() {memory_space = #gpu.address_space<workgroup>} : tensor<16x64xf32>
        %15 = scf.forall (%arg8, %arg9) in (16, 16) shared_outs(%arg10 = %14) -> (tensor<16x64xf32>) {
          %17 = affine.apply #map3(%arg9)
          %extracted_slice_6 = tensor.extract_slice %extracted_slice_5[%arg8, %17] [1, 4] [1, 1] : tensor<16x64xf32> to tensor<1x4xf32>
          %18 = affine.apply #map3(%arg9)
          scf.forall.in_parallel {
            tensor.parallel_insert_slice %extracted_slice_6 into %arg10[%arg8, %18] [1, 4] [1, 1] : tensor<1x4xf32> into tensor<16x64xf32>
          }
        } {mapping = [#gpu.thread<linear_dim_1>, #gpu.thread<linear_dim_0>]}
        %16 = scf.forall (%arg8, %arg9) in (16, 16) shared_outs(%arg10 = %arg7) -> (tensor<128x64xf32>) {
          %17 = affine.apply #map2(%arg8)
          %18 = affine.apply #map3(%arg9)
          %19 = affine.apply #map2(%arg8)
          %20 = affine.apply #map3(%arg9)
          %extracted_slice_6 = tensor.extract_slice %13[%17, 0] [8, 16] [1, 1] : tensor<128x16xf32> to tensor<8x16xf32>
          %extracted_slice_7 = tensor.extract_slice %15[0, %18] [16, 4] [1, 1] : tensor<16x64xf32> to tensor<16x4xf32>
          %extracted_slice_8 = tensor.extract_slice %arg10[%19, %20] [8, 4] [1, 1] : tensor<128x64xf32> to tensor<8x4xf32>
          %21 = vector.transfer_read %extracted_slice_6[%c0, %c0], %cst_0 {in_bounds = [true, true]} : tensor<8x16xf32>, vector<8x16xf32>
          %22 = vector.transfer_read %extracted_slice_7[%c0, %c0], %cst_0 {in_bounds = [true, true]} : tensor<16x4xf32>, vector<16x4xf32>
          %23 = vector.transfer_read %extracted_slice_8[%c0, %c0], %cst_0 {in_bounds = [true, true]} : tensor<8x4xf32>, vector<8x4xf32>
          %24 = vector.contract {indexing_maps = [#map5, #map6, #map7], iterator_types = ["parallel", "parallel", "reduction"], kind = #vector.kind<add>} %21, %22, %23 : vector<8x16xf32>, vector<16x4xf32> into vector<8x4xf32>
          %25 = vector.transfer_write %24, %extracted_slice_8[%c0, %c0] {in_bounds = [true, true]} : vector<8x4xf32>, tensor<8x4xf32>
          %26 = affine.apply #map2(%arg8)
          %27 = affine.apply #map3(%arg9)
          scf.forall.in_parallel {
            tensor.parallel_insert_slice %25 into %arg10[%26, %27] [8, 4] [1, 1] : tensor<8x4xf32> into tensor<128x64xf32>
          }
        } {mapping = [#gpu.thread<y>, #gpu.thread<x>]}
        scf.yield %16 : tensor<128x64xf32>
      }
      %11 = scf.forall (%arg6, %arg7) in (16, 16) shared_outs(%arg8 = %10) -> (tensor<128x64xf32>) {
        %12 = affine.apply #map3(%arg7)
        %13 = affine.apply #map2(%arg6)
        %14 = affine.apply #map3(%arg7)
        %extracted_slice_4 = tensor.extract_slice %extracted_slice[%12] [4] [1] : tensor<64xf32> to tensor<4xf32>
        %extracted_slice_5 = tensor.extract_slice %arg8[%13, %14] [8, 4] [1, 1] : tensor<128x64xf32> to tensor<8x4xf32>
        %15 = vector.transfer_read %extracted_slice_4[%c0], %0 {in_bounds = [true, true], permutation_map = #map8} : tensor<4xf32>, vector<8x4xf32>
        %16 = vector.transfer_read %extracted_slice_5[%c0, %c0], %0 {in_bounds = [true, true]} : tensor<8x4xf32>, vector<8x4xf32>
        %17 = arith.addf %16, %15 : vector<8x4xf32>
        %18 = arith.maximumf %17, %cst : vector<8x4xf32>
        %19 = vector.transfer_write %18, %extracted_slice_5[%c0, %c0] {in_bounds = [true, true]} : vector<8x4xf32>, tensor<8x4xf32>
        %20 = affine.apply #map2(%arg6)
        %21 = affine.apply #map3(%arg7)
        scf.forall.in_parallel {
          tensor.parallel_insert_slice %19 into %arg8[%20, %21] [8, 4] [1, 1] : tensor<8x4xf32> into tensor<128x64xf32>
        }
      } {mapping = [#gpu.thread<y>, #gpu.thread<x>]}
      scf.forall.in_parallel {
        tensor.parallel_insert_slice %11 into %arg5[%3, %4] [128, 64] [1, 1] : tensor<128x64xf32> into tensor<2048x2048xf32>
      }
    } {mapping = [#gpu.block<y>, #gpu.block<x>]}
    return %2 : tensor<2048x2048xf32>
  }
}


// tforge transform script
module attributes {transform.with_named_sequence} {
transform.named_sequence @__transform_main(%arg0: !transform.any_op) {
  %l = transform.gpu.map_forall_to_blocks %arg0 generate_gpu_launch : (!transform.any_op) -> !transform.any_op
  %t = transform.gpu.map_nested_forall_to_threads %l block_dims = [16, 16, 1] : (!transform.any_op) -> !transform.any_op
  transform.yield
}
}

// tforge transform script
module attributes {transform.with_named_sequence} {
transform.named_sequence @__transform_main(%arg0: !transform.any_op) {
  transform.apply_patterns to %arg0 {
    transform.apply_patterns.vector.transfer_to_scf max_transfer_rank = 1 full_unroll = true
  } : !transform.any_op
  transform.apply_patterns to %arg0 {
    transform.apply_patterns.vector.lower_contraction lowering_strategy = outerproduct
    transform.apply_patterns.vector.lower_outerproduct
    transform.apply_patterns.vector.transfer_permutation_patterns
    transform.apply_patterns.vector.lower_transfer max_transfer_rank = 1
    transform.apply_patterns.vector.lower_broadcast
    transform.apply_patterns.vector.lower_shape_cast
    transform.apply_patterns.vector.lower_transpose
    transform.apply_patterns.canonicalization
  } : !transform.any_op
  transform.yield
}
}

