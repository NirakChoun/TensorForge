// Every verifier rejection, one case per split.
// RUN: tensorforge-opt %s --split-input-file --verify-diagnostics

func.func @not_a_tensor(%a: f32) {
  // expected-error @+1 {{'tforge.relu' op operand #0 must be tensor of any non-token type values, but got 'f32'}}
  %0 = "tforge.relu"(%a) : (f32) -> tensor<4xf32>
  return
}

// -----

func.func @unranked(%a: tensor<*xf32>) {
  // expected-error @+1 {{'tforge.add' op lhs must be a ranked tensor, but got 'tensor<*xf32>'}}
  %0 = tforge.add %a, %a : tensor<*xf32>, tensor<*xf32> -> tensor<4xf32>
  return
}

// -----

func.func @dynamic(%a: tensor<?x4xf32>) {
  // expected-error @+1 {{'tforge.relu' op input must have a static shape, but got 'tensor<?x4xf32>'}}
  %0 = tforge.relu %a : tensor<?x4xf32> -> tensor<?x4xf32>
  return
}

// -----

func.func @f16(%a: tensor<4xf16>) {
  // expected-error @+1 {{'tforge.relu' op input must have f32 elements, but has element type 'f16'}}
  %0 = tforge.relu %a : tensor<4xf16> -> tensor<4xf16>
  return
}

// -----

func.func @int(%a: tensor<4xi32>, %b: tensor<4xf32>) {
  // expected-error @+1 {{'tforge.add' op lhs must have f32 elements, but has element type 'i32'}}
  %0 = tforge.add %a, %b : tensor<4xi32>, tensor<4xf32> -> tensor<4xf32>
  return
}

// -----

func.func @result_elem(%a: tensor<4xf32>) {
  // expected-error @+1 {{'tforge.relu' op result must have f32 elements, but has element type 'f64'}}
  %0 = tforge.relu %a : tensor<4xf32> -> tensor<4xf64>
  return
}

// -----

func.func @add_shape(%a: tensor<4x8xf32>, %b: tensor<4x7xf32>) {
  // expected-error @+1 {{'tforge.add' op operand shapes must match (no implicit broadcasting): lhs is 4x8, rhs is 4x7}}
  %0 = tforge.add %a, %b : tensor<4x8xf32>, tensor<4x7xf32> -> tensor<4x8xf32>
  return
}

// -----

func.func @add_broadcast(%a: tensor<4x8xf32>, %b: tensor<8xf32>) {
  // expected-error @+1 {{'tforge.add' op operand shapes must match (no implicit broadcasting): lhs is 4x8, rhs is 8}}
  %0 = tforge.add %a, %b : tensor<4x8xf32>, tensor<8xf32> -> tensor<4x8xf32>
  return
}

// -----

func.func @add_result(%a: tensor<4x8xf32>) {
  // expected-error @+1 {{'tforge.add' op result shape 8x4 does not match operand shape 4x8}}
  %0 = tforge.add %a, %a : tensor<4x8xf32>, tensor<4x8xf32> -> tensor<8x4xf32>
  return
}

// -----

func.func @relu_result(%a: tensor<4x8xf32>) {
  // expected-error @+1 {{'tforge.relu' op result shape 4x9 does not match input shape 4x8}}
  %0 = tforge.relu %a : tensor<4x8xf32> -> tensor<4x9xf32>
  return
}

// -----

func.func @matmul_rank(%a: tensor<2x4x8xf32>, %b: tensor<8x4xf32>) {
  // expected-error @+1 {{'tforge.matmul' op lhs must be rank 2 (M x K), but has rank 3}}
  %0 = tforge.matmul %a, %b : tensor<2x4x8xf32>, tensor<8x4xf32> -> tensor<4x4xf32>
  return
}

// -----

func.func @matmul_rhs_rank(%a: tensor<4x8xf32>, %b: tensor<8xf32>) {
  // expected-error @+1 {{'tforge.matmul' op rhs must be rank 2 (K x N), but has rank 1}}
  %0 = tforge.matmul %a, %b : tensor<4x8xf32>, tensor<8xf32> -> tensor<4xf32>
  return
}

// -----

func.func @matmul_k(%a: tensor<64x32xf32>, %b: tensor<16x16xf32>) {
  // expected-error @+1 {{'tforge.matmul' op contracting dimensions do not match: lhs is 64x32 (K = 32), rhs is 16x16 (K = 16)}}
  %0 = tforge.matmul %a, %b : tensor<64x32xf32>, tensor<16x16xf32> -> tensor<64x16xf32>
  return
}

// -----

func.func @matmul_result(%a: tensor<64x32xf32>, %b: tensor<32x16xf32>) {
  // expected-error @+1 {{'tforge.matmul' op result shape must be 64x16 (M x N), but got 16x64}}
  %0 = tforge.matmul %a, %b : tensor<64x32xf32>, tensor<32x16xf32> -> tensor<16x64xf32>
  return
}

// -----

func.func @bias_rank(%a: tensor<4x8xf32>, %b: tensor<1x8xf32>) {
  // expected-error @+1 {{'tforge.bias_add' op bias must be rank 1, but has rank 2}}
  %0 = tforge.bias_add %a, %b : tensor<4x8xf32>, tensor<1x8xf32> -> tensor<4x8xf32>
  return
}

// -----

func.func @bias_len(%a: tensor<4x8xf32>, %b: tensor<4xf32>) {
  // expected-error @+1 {{'tforge.bias_add' op bias length 4 does not match the last dimension of input 4x8 (8)}}
  %0 = tforge.bias_add %a, %b : tensor<4x8xf32>, tensor<4xf32> -> tensor<4x8xf32>
  return
}

// -----

func.func @bias_scalar(%a: tensor<f32>, %b: tensor<1xf32>) {
  // expected-error @+1 {{'tforge.bias_add' op input must have rank >= 1, but is a scalar}}
  %0 = tforge.bias_add %a, %b : tensor<f32>, tensor<1xf32> -> tensor<f32>
  return
}

// -----

func.func @bias_result(%a: tensor<4x8xf32>, %b: tensor<8xf32>) {
  // expected-error @+1 {{'tforge.bias_add' op result shape 4x7 does not match input shape 4x8}}
  %0 = tforge.bias_add %a, %b : tensor<4x8xf32>, tensor<8xf32> -> tensor<4x7xf32>
  return
}
