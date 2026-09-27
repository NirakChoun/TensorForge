// relu(x @ w + b): the fused workload TensorForge is evaluated on.
// See README.md ("Worked example") for the commands that compile and run it.
func.func @entry(%x: tensor<256x128xf32>, %w: tensor<128x256xf32>, %b: tensor<256xf32>) -> tensor<256x256xf32> {
  %mm = tforge.matmul %x, %w : tensor<256x128xf32>, tensor<128x256xf32> -> tensor<256x256xf32>
  %ba = tforge.bias_add %mm, %b : tensor<256x256xf32>, tensor<256xf32> -> tensor<256x256xf32>
  %r = tforge.relu %ba : tensor<256x256xf32> -> tensor<256x256xf32>
  return %r : tensor<256x256xf32>
}
