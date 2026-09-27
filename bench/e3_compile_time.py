#!/usr/bin/env python3
"""E3: compile time of each TensorForge pipeline, per step.

Each step is run 5 times (after one untimed run), and the median wall time is
reported: tensorforge-opt (the MLIR pipeline), mlir-translate, opt -O3, llc -O3,
and the final step (shared-object link on CPU, ptxas on GPU). One run per
configuration is repeated with --mlir-timing to break the MLIR pipeline time
down by pass (results/compile/timing_*.txt).
"""

import argparse
import csv
import os
import pathlib
import statistics
import subprocess
import sys
import tempfile
import time

sys.path.insert(0, str(pathlib.Path(__file__).resolve().parent.parent / "python"))
import provenance  # noqa: E402
import tforge_cpu as tc  # noqa: E402

CONFIGS = [
    ("cpu-baseline", "cpu", ""),
    ("cpu-fused-vectorized", "cpu", "fuse-elementwise=1 reg-tile=6,16,4 vectorize=1"),
    ("gpu-naive", "gpu", "block-tile=16,16 thread-tile=1,1"),
    ("gpu-staged", "gpu", "block-tile=128,64 thread-tile=8,4 tile-k=16 promote=1 vectorize=1"),
]
SHAPES = [(256, 256, 256), (1024, 1024, 1024), (4096, 4096, 4096)]
REPS = 5


def timed(cmd):
    t0 = time.perf_counter()
    r = subprocess.run([str(c) for c in cmd], capture_output=True, text=True, timeout=600)
    dt = time.perf_counter() - t0
    if r.returncode != 0:
        raise RuntimeError(r.stderr)
    return dt, r


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--csv", default="results/compile/e3.csv")
    args = ap.parse_args()
    outdir = pathlib.Path(args.csv).parent
    outdir.mkdir(parents=True, exist_ok=True)
    base = provenance.common()
    f = open(args.csv, "w", newline="")
    w = csv.writer(f)
    w.writerow(["commit", "mlir_llvm_version", "cuda_version", "job_id", "date", "host_cpu", "config",
                "pipeline", "shape", "step", "median_s", "min_s", "reps"])
    cpu = provenance.cpu_model()
    cxx = os.environ.get("CXX", "c++")
    for name, target, opts in CONFIGS:
        for m, n, k in SHAPES:
            with tempfile.TemporaryDirectory() as td:
                d = pathlib.Path(td)
                (d / "in.mlir").write_text(tc.gen_mlir("mbr", m, n, k))
                flag = f"--tforge-{target}-pipeline={opts}" if opts else f"--tforge-{target}-pipeline"
                steps = [("tensorforge-opt", [tc.OPT, d / "in.mlir", flag, "-o", d / "o.mlir"]),
                         ("mlir-translate", ["mlir-translate", "--mlir-to-llvmir", d / "o.mlir", "-o", d / "k.ll"])]
                if target == "cpu":
                    steps += [("opt -O3", ["opt", "-O3", "-S", d / "k.ll", "-o", d / "k.opt.ll"]),
                              ("llc -O3", ["llc", "-O3", "-mcpu=native", "-relocation-model=pic", "-filetype=obj",
                                           d / "k.opt.ll", "-o", d / "k.o"]),
                              ("link .so", [cxx, "-shared", d / "k.o", "-o", d / "k.so"])]
                else:
                    steps += [("opt -O3", ["opt", "-O3", "-mcpu=sm_120", "-S", d / "k.ll", "-o", d / "k.opt.ll"]),
                              ("llc -O3", ["llc", "-O3", "-march=nvptx64", "-mcpu=sm_120", "-fp-contract=fast",
                                           d / "k.opt.ll", "-o", d / "k.ptx"]),
                              ("ptxas -O3", ["ptxas", "-O3", "-arch=sm_120", d / "k.ptx", "-o", d / "k.cubin"])]
                totals = []
                for step, cmd in steps:
                    timed(cmd)  # untimed warm run (page cache)
                    ts = [timed(cmd)[0] for _ in range(REPS)]
                    totals.append(statistics.median(ts))
                    w.writerow([base["commit"], base["mlir_llvm_version"], base["cuda_version"], base["job_id"],
                                base["date"], cpu, name, flag, f"{m}x{n}x{k}", step,
                                f"{statistics.median(ts):.4f}", f"{min(ts):.4f}", REPS])
                w.writerow([base["commit"], base["mlir_llvm_version"], base["cuda_version"], base["job_id"],
                            base["date"], cpu, name, flag, f"{m}x{n}x{k}", "total (sum of medians)",
                            f"{sum(totals):.4f}", "", REPS])
                f.flush()
                _, r = timed([tc.OPT, d / "in.mlir", flag, "--mlir-timing", "-o", "/dev/null"])
                (outdir / f"timing_{name}_{m}x{n}x{k}.txt").write_text(r.stderr)
                print(f"{name} {m}x{n}x{k}: total {sum(totals):.3f} s "
                      + " ".join(f"{s}={t:.3f}" for (s, _), t in zip(steps, totals)), flush=True)
    return 0


if __name__ == "__main__":
    sys.exit(main())
