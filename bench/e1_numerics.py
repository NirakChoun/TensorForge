#!/usr/bin/env python3
"""E1: which TensorForge transformations change floating-point results, and by how much.

For relu(A @ B + bias) and plain matmul, every variant runs on the same inputs.
Reported per variant:
  - max |x - x64|, RMS |x - x64|, and max |x - x64| / bound against the FP64
    reference (bound = gamma_{K+1} (|A||B| + |bias|), valid for any summation
    order),
  - the number and fraction of output elements that differ bitwise from the CPU
    scalar kernel (sequential k order, separate multiply and add), which is the
    reference f32 evaluation order of the tforge semantics.

Variants: CPU scalar baseline; CPU fused and tiled (32x32, scalar); CPU
vectorized with KR = 1 and KR = 4; NumPy/OpenBLAS (1 thread); GPU naive (one
output per thread, FFMA); GPU staged with BK = 8, 16, 32; cuBLAS FP32.
"""

import argparse
import csv
import os
import pathlib
import sys
import tempfile

os.environ.setdefault("OPENBLAS_NUM_THREADS", "1")
sys.path.insert(0, str(pathlib.Path(__file__).resolve().parent.parent / "python"))
import numpy as np  # noqa: E402

import provenance  # noqa: E402
import tforge_cpu as tc  # noqa: E402
import tforge_gpu as tg  # noqa: E402

SHAPES = [(256, 256, 256), (1000, 1000, 1000), (777, 1111, 333), (512, 512, 4096)]
CPU = [("cpu-scalar", ""), ("cpu-fused-tiled-32", "fuse-elementwise=1 tile-sizes=32,32"),
       ("cpu-vec-kr1", "fuse-elementwise=1 reg-tile=6,16,1 vectorize=1"),
       ("cpu-vec-kr4", "fuse-elementwise=1 reg-tile=6,16,4 vectorize=1")]
GPU = [("gpu-naive", "block-tile=16,16 thread-tile=1,1"),
       ("gpu-staged-bk8", "block-tile=128,64 thread-tile=8,4 tile-k=8 promote=1 vectorize=1"),
       ("gpu-staged-bk16", "block-tile=128,64 thread-tile=8,4 tile-k=16 promote=1 vectorize=1"),
       ("gpu-staged-bk32", "block-tile=128,64 thread-tile=8,4 tile-k=32 promote=1 vectorize=1")]


def cpu_output(workload, m, n, k, kdir, ins):
    with tempfile.TemporaryDirectory() as td:
        for name, arr in ins.items():
            arr.tofile(f"{td}/{name}.bin")
        tc.run([tc.BENCH, "--lib", kdir / "k.so", "--workload", workload, "--m", m, "--n", n, "--k", k,
                "--warmup", 0, "--reps", 1, "--in-dir", td, "--out", f"{td}/o.bin"])
        return np.fromfile(f"{td}/o.bin", dtype=np.float32).reshape(m, n)


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--csv", default="results/numerics/e1.csv")
    args = ap.parse_args()
    base = provenance.common()
    path = pathlib.Path(args.csv)
    path.parent.mkdir(parents=True, exist_ok=True)
    f = open(path, "w", newline="")
    w = csv.writer(f)
    w.writerow(["commit", "mlir_llvm_version", "cuda_version", "job_id", "date", "device", "workload",
                "shape", "dtype", "variant", "pipeline", "max_abs_err", "rms_err", "max_err_over_bound",
                "bitwise_diff_vs_cpu_scalar", "bitwise_diff_fraction", "max_abs_diff_vs_cpu_scalar",
                "bitwise_diff_vs_gpu_naive"])
    cpu_dev, gpu_dev = provenance.cpu_model(), "NVIDIA RTX PRO 6000 Blackwell Max-Q Workstation Edition"
    for workload in ("mbr", "matmul"):
        for m, n, k in SHAPES:
            ins = tc.make_inputs(workload, m, n, k)
            a64, b64 = ins["a"].astype(np.float64), ins["b"].astype(np.float64)
            ref, mag, steps = a64 @ b64, np.abs(a64) @ np.abs(b64), k
            if workload == "mbr":
                bias64 = ins["bias"].astype(np.float64)
                ref, mag, steps = np.maximum(ref + bias64, 0), mag + np.abs(bias64), k + 1
            bound = steps * tc.F32_EPS / (1 - steps * tc.F32_EPS) * mag + np.finfo(np.float32).tiny
            outs = []
            for name, opts in CPU:
                d = tc.compile_kernel(workload, m, n, k, opts, tag=f"e1/{name}")
                outs.append((name, f"tforge-cpu-pipeline{{{opts}}}", cpu_dev, cpu_output(workload, m, n, k, d, ins)))
            npo = ins["a"] @ ins["b"]
            if workload == "mbr":
                npo = np.maximum(npo + ins["bias"], np.float32(0))
            outs.append(("numpy-openblas", "numpy matmul (+ add, maximum), 1 thread", cpu_dev, npo))
            for name, opts in GPU:
                d, launch = tg.compile_kernel(workload, m, n, k, opts, tag=f"e1/{name}")
                _, o = tg.check(workload, m, n, k, d, launch)
                outs.append((name, f"tforge-gpu-pipeline{{{opts}}}", gpu_dev, o))
            _, o = tg.check(workload, m, n, k, mode="cublas")
            outs.append(("cublas", "cublasSgemm FP32 default math" + (" + bias_relu" if workload == "mbr" else ""),
                         gpu_dev, o))
            scalar = outs[0][3]
            # gpu-naive: one FFMA per k, in sequential k order.
            fma_seq = next(o for nm, _, _, o in outs if nm == "gpu-naive")
            for name, pipe, dev, o in outs:
                err = np.abs(o.astype(np.float64) - ref)
                diff = int(np.count_nonzero(o.view(np.uint32) != scalar.view(np.uint32)))
                diff_fma = int(np.count_nonzero(o.view(np.uint32) != fma_seq.view(np.uint32)))
                w.writerow([base["commit"], base["mlir_llvm_version"], base["cuda_version"], base["job_id"],
                            base["date"], dev, workload, f"{m}x{n}x{k}", "f32", name, pipe,
                            f"{err.max():.4g}", f"{np.sqrt((err ** 2).mean()):.4g}",
                            f"{(err / bound).max():.4g}", diff, f"{diff / o.size:.4f}",
                            f"{np.abs(o.astype(np.float64) - scalar).max():.4g}", diff_fma])
                print(f"{workload} {m}x{n}x{k} {name:>20}: max_err={err.max():.3g} "
                      f"err/bound={(err / bound).max():.3g} bitwise-diff={diff / o.size:.3f} "
                      f"vs-naive={diff_fma / o.size:.3f}", flush=True)
            f.flush()
    return 0


if __name__ == "__main__":
    sys.exit(main())
