func.func @entry(%a: tensor<1024x1024xf32>, %b: tensor<1024x1024xf32>, %bias: tensor<1024xf32>) -> tensor<1024x1024xf32> {
  %0 = tforge.matmul %a, %b : tensor<1024x1024xf32>, tensor<1024x1024xf32> -> tensor<1024x1024xf32>
  %1 = tforge.bias_add %0, %bias : tensor<1024x1024xf32>, tensor<1024xf32> -> tensor<1024x1024xf32>
  %2 = tforge.relu %1 : tensor<1024x1024xf32> -> tensor<1024x1024xf32>
  return %2 : tensor<1024x1024xf32>
}
