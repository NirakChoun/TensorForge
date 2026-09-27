// tforge folds under --canonicalize. Each function body is the "before"; the
// CHECK lines are the "after".
// RUN: tensorforge-opt %s --canonicalize --split-input-file | FileCheck %s

// relu(relu(x)) -> relu(x), for any chain length.
// CHECK-LABEL: func.func @relu_relu
// CHECK-SAME:    (%[[X:.*]]: tensor<4x8xf32>)
// CHECK-NEXT:    %[[R:.*]] = tforge.relu %[[X]]
// CHECK-NEXT:    return %[[R]], %[[R]]
func.func @relu_relu(%x: tensor<4x8xf32>) -> (tensor<4x8xf32>, tensor<4x8xf32>) {
  %0 = tforge.relu %x : tensor<4x8xf32> -> tensor<4x8xf32>
  %1 = tforge.relu %0 : tensor<4x8xf32> -> tensor<4x8xf32>
  %2 = tforge.relu %1 : tensor<4x8xf32> -> tensor<4x8xf32>
  return %1, %2 : tensor<4x8xf32>, tensor<4x8xf32>
}

// -----

// add(x, -0.0 splat) -> x on either side: x + (-0.0) == x for every x.
// CHECK-LABEL: func.func @add_neg_zero
// CHECK-SAME:    (%[[X:.*]]: tensor<4x8xf32>)
// CHECK-NOT:     tforge.add
// CHECK:         return %[[X]], %[[X]]
func.func @add_neg_zero(%x: tensor<4x8xf32>) -> (tensor<4x8xf32>, tensor<4x8xf32>) {
  %z = arith.constant dense<-0.0> : tensor<4x8xf32>
  %0 = tforge.add %x, %z : tensor<4x8xf32>, tensor<4x8xf32> -> tensor<4x8xf32>
  %1 = tforge.add %z, %x : tensor<4x8xf32>, tensor<4x8xf32> -> tensor<4x8xf32>
  return %0, %1 : tensor<4x8xf32>, tensor<4x8xf32>
}

// -----

// add(x, +0.0 splat) is NOT folded for arbitrary x: (-0.0) + (+0.0) = +0.0.
// CHECK-LABEL: func.func @add_pos_zero_kept
// CHECK-SAME:    (%[[X:.*]]: tensor<4x8xf32>)
// CHECK:         %[[Z:.*]] = arith.constant dense<0.000000e+00> : tensor<4x8xf32>
// CHECK:         %[[A:.*]] = tforge.add %[[X]], %[[Z]]
// CHECK:         return %[[A]]
func.func @add_pos_zero_kept(%x: tensor<4x8xf32>) -> tensor<4x8xf32> {
  %z = arith.constant dense<0.0> : tensor<4x8xf32>
  %0 = tforge.add %z, %x : tensor<4x8xf32>, tensor<4x8xf32> -> tensor<4x8xf32>
  return %0 : tensor<4x8xf32>
}

// -----

// add(relu(y), +0.0 splat) -> relu(y): relu never produces -0.0.
// CHECK-LABEL: func.func @add_pos_zero_after_relu
// CHECK-SAME:    (%[[Y:.*]]: tensor<4x8xf32>)
// CHECK-NEXT:    %[[R:.*]] = tforge.relu %[[Y]]
// CHECK-NEXT:    return %[[R]]
func.func @add_pos_zero_after_relu(%y: tensor<4x8xf32>) -> tensor<4x8xf32> {
  %z = arith.constant dense<0.0> : tensor<4x8xf32>
  %r = tforge.relu %y : tensor<4x8xf32> -> tensor<4x8xf32>
  %0 = tforge.add %r, %z : tensor<4x8xf32>, tensor<4x8xf32> -> tensor<4x8xf32>
  return %0 : tensor<4x8xf32>
}

// -----

// A zero constant that is not a splat of one signed zero is not folded.
// CHECK-LABEL: func.func @add_mixed_zero_kept
// CHECK:         tforge.add
func.func @add_mixed_zero_kept(%x: tensor<2xf32>) -> tensor<2xf32> {
  %z = arith.constant dense<[-0.0, 0.0]> : tensor<2xf32>
  %0 = tforge.add %x, %z : tensor<2xf32>, tensor<2xf32> -> tensor<2xf32>
  return %0 : tensor<2xf32>
}

// -----

// Constant folding of add: dense and splat operands.
// CHECK-LABEL: func.func @add_const
// CHECK-DAG:     %[[D:.*]] = arith.constant dense<[1.500000e+00, -1.000000e+00]> : tensor<2xf32>
// CHECK-DAG:     %[[S:.*]] = arith.constant dense<3.000000e+00> : tensor<2x3xf32>
// CHECK-NOT:     tforge.add
// CHECK:         return %[[D]], %[[S]]
func.func @add_const() -> (tensor<2xf32>, tensor<2x3xf32>) {
  %a = arith.constant dense<[1.0, 2.0]> : tensor<2xf32>
  %b = arith.constant dense<[0.5, -3.0]> : tensor<2xf32>
  %0 = tforge.add %a, %b : tensor<2xf32>, tensor<2xf32> -> tensor<2xf32>
  %c = arith.constant dense<1.0> : tensor<2x3xf32>
  %d = arith.constant dense<2.0> : tensor<2x3xf32>
  %1 = tforge.add %c, %d : tensor<2x3xf32>, tensor<2x3xf32> -> tensor<2x3xf32>
  return %0, %1 : tensor<2xf32>, tensor<2x3xf32>
}

// -----

// Constant folding of relu keeps IEEE maximum semantics: -0.0 -> +0.0,
// NaN -> NaN, negatives -> +0.0.
// CHECK-LABEL: func.func @relu_const
// CHECK:         %[[C:.*]] = arith.constant dense<[0.000000e+00, 0.000000e+00, 0x7FC00000, 2.500000e+00, 0.000000e+00]> : tensor<5xf32>
// CHECK-NOT:     tforge.relu
// CHECK:         return %[[C]]
func.func @relu_const() -> tensor<5xf32> {
  %a = arith.constant dense<[-1.0, -0.0, 0x7FC00000, 2.5, 0.0]> : tensor<5xf32>
  %0 = tforge.relu %a : tensor<5xf32> -> tensor<5xf32>
  return %0 : tensor<5xf32>
}

// -----

// Constant folding of bias_add broadcasts along the last dimension, and folds
// compose: relu(bias_add(c, b)) becomes one constant.
// CHECK-LABEL: func.func @bias_add_const
// CHECK:         %[[C:.*]] = arith.constant dense<{{\[}}[1.100000e+01, 0.000000e+00], [1.300000e+01, 0.000000e+00]]> : tensor<2x2xf32>
// CHECK-NOT:     tforge.
// CHECK:         return %[[C]]
func.func @bias_add_const() -> tensor<2x2xf32> {
  %a = arith.constant dense<[[1.0, 2.0], [3.0, 4.0]]> : tensor<2x2xf32>
  %b = arith.constant dense<[10.0, -20.0]> : tensor<2xf32>
  %0 = tforge.bias_add %a, %b : tensor<2x2xf32>, tensor<2xf32> -> tensor<2x2xf32>
  %1 = tforge.relu %0 : tensor<2x2xf32> -> tensor<2x2xf32>
  return %1 : tensor<2x2xf32>
}

// -----

// bias_add with a -0.0 splat bias is the identity.
// CHECK-LABEL: func.func @bias_add_neg_zero
// CHECK-SAME:    (%[[X:.*]]: tensor<3x4xf32>)
// CHECK-NEXT:    return %[[X]]
func.func @bias_add_neg_zero(%x: tensor<3x4xf32>) -> tensor<3x4xf32> {
  %z = arith.constant dense<-0.0> : tensor<4xf32>
  %0 = tforge.bias_add %x, %z : tensor<3x4xf32>, tensor<4xf32> -> tensor<3x4xf32>
  return %0 : tensor<3x4xf32>
}

// -----

// matmul is not constant-folded (only elementwise ops are), and unused pure
// ops are erased.
// CHECK-LABEL: func.func @matmul_not_folded
// CHECK:         %[[M:.*]] = tforge.matmul
// CHECK-NOT:     tforge.relu
// CHECK:         return %[[M]]
func.func @matmul_not_folded() -> tensor<2x2xf32> {
  %a = arith.constant dense<1.0> : tensor<2x3xf32>
  %b = arith.constant dense<2.0> : tensor<3x2xf32>
  %0 = tforge.matmul %a, %b : tensor<2x3xf32>, tensor<3x2xf32> -> tensor<2x2xf32>
  %unused = tforge.relu %0 : tensor<2x2xf32> -> tensor<2x2xf32>
  return %0 : tensor<2x2xf32>
}
