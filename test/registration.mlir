// The dialects and passes every later stage depends on must be registered.

// RUN: tensorforge-opt --show-dialects | FileCheck %s --check-prefix=DIALECTS
// DIALECTS-DAG: arith
// DIALECTS-DAG: bufferization
// DIALECTS-DAG: gpu
// DIALECTS-DAG: linalg
// DIALECTS-DAG: memref
// DIALECTS-DAG: nvvm
// DIALECTS-DAG: scf
// DIALECTS-DAG: tensor
// DIALECTS-DAG: transform
// DIALECTS-DAG: vector

// RUN: tensorforge-opt --help | FileCheck %s --check-prefix=PASSES
// PASSES-DAG: --canonicalize
// PASSES-DAG: --one-shot-bufferize
// PASSES-DAG: --convert-linalg-to-loops
// PASSES-DAG: --gpu-kernel-outlining
// PASSES-DAG: --transform-interpreter

// Upstream passes run through the driver.
// RUN: tensorforge-opt %s --canonicalize | FileCheck %s --check-prefix=CANON
// CANON-LABEL: func.func @fold
// CANON-NEXT:    %[[C:.*]] = arith.constant 3 : i32
// CANON-NEXT:    return %[[C]]
func.func @fold() -> i32 {
  %a = arith.constant 1 : i32
  %b = arith.constant 2 : i32
  %c = arith.addi %a, %b : i32
  return %c : i32
}
