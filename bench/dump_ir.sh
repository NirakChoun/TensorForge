#!/bin/bash
# Dump the IR of a tforge workload at the main points of the CPU pipeline, as
# evidence for the stage reports.
#
#   bench/dump_ir.sh <outdir> <workload> <M> <N> <K|-> "<cpu pipeline options>"
#
# Writes <outdir>/:
#   0_input.mlir         the tforge program
#   1_linalg.mlir        after convert-tforge-to-linalg
#   2_transformed.mlir   right before one-shot-bufferize (after fusion/tiling/vectorization)
#   3_bufferized.mlir    right before convert-linalg-to-loops
#   4_llvm.mlir          pipeline output (LLVM dialect)
#   5_asm.s              opt -O3 + llc -O3 -mcpu=native assembly
#   pipeline.txt         the expanded pass pipeline
set -euo pipefail
cd "$(dirname "$0")/.."
out="$1"; wl="$2"; m="$3"; n="$4"; k="$5"; opts="${6:-}"
[[ "$k" == "-" ]] && k=None
mkdir -p "$out"
OPT=./build/bin/tensorforge-opt
P="--tforge-cpu-pipeline=$opts"

python3 -c "import sys; sys.path.insert(0,'python'); import tforge_cpu as t; \
print(t.gen_mlir('$wl', $m, $n, $k), end='')" > "$out/0_input.mlir"
$OPT "$out/0_input.mlir" "$P" --dump-pass-pipeline -o /dev/null 2> "$out/pipeline.txt"
$OPT "$out/0_input.mlir" --convert-tforge-to-linalg --canonicalize -o "$out/1_linalg.mlir"
$OPT "$out/0_input.mlir" "$P" --mlir-print-ir-before=one-shot-bufferize -o /dev/null \
  2> "$out/2_transformed.mlir"
$OPT "$out/0_input.mlir" "$P" --mlir-print-ir-before=convert-linalg-to-loops -o /dev/null \
  2> "$out/3_bufferized.mlir"
$OPT "$out/0_input.mlir" "$P" -o "$out/4_llvm.mlir"
mlir-translate --mlir-to-llvmir "$out/4_llvm.mlir" | opt -O3 | llc -O3 -mcpu=native -o "$out/5_asm.s"
echo "wrote $out"
