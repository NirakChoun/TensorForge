func.func @entry(%a: tensor<2048x2048xf32>, %b: tensor<2048x2048xf32>, %bias: tensor<2048xf32>) -> tensor<2048x2048xf32> {
  %0 = tforge.matmul %a, %b : tensor<2048x2048xf32>, tensor<2048x2048xf32> -> tensor<2048x2048xf32>
  %1 = tforge.bias_add %0, %bias : tensor<2048x2048xf32>, tensor<2048xf32> -> tensor<2048x2048xf32>
  %2 = tforge.relu %1 : tensor<2048x2048xf32> -> tensor<2048x2048xf32>
  return %2 : tensor<2048x2048xf32>
}
