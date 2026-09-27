#!/usr/bin/env python3
"""CPU correctness + timing driver for TensorForge kernels.

Every (variant, workload, shape) is compiled, checked against NumPy / FP64,
and only then timed. A failed check is recorded and the timing is skipped.

  python3 bench/cpu_bench.py --csv results/cpu/stage4.csv --tag stage4 \
      --variant baseline= --workloads add,relu,matmul,mbr --numpy

--variant NAME=OPTIONS may be repeated; OPTIONS is the --tforge-cpu-pipeline
option string (empty for the default pipeline).
"""

import argparse
import os
import pathlib
import sys
import time

# NumPy baselines are single-threaded, matching the single-threaded kernels.
os.environ.setdefault("OPENBLAS_NUM_THREADS", "1")
os.environ.setdefault("OMP_NUM_THREADS", "1")

sys.path.insert(0, str(pathlib.Path(__file__).resolve().parent.parent / "python"))
import numpy as np  # noqa: E402

import provenance  # noqa: E402
import tforge_cpu as tc  # noqa: E402

ELEMENTWISE_SHAPES = [(33, 17), (999, 1001), (1024, 1024), (4096, 4096)]
MATMUL_SHAPES = [(64, 64, 64), (127, 129, 65), (256, 256, 256), (250, 330, 170),
                 (512, 512, 512)]


def shapes_for(workload):
    if workload in ("add", "relu"):
        return [(m, n, None) for m, n in ELEMENTWISE_SHAPES]
    return MATMUL_SHAPES


def shape_str(m, n, k):
    return f"{m}x{n}" + (f"x{k}" if k else "")


def numpy_blas():
    """conda-forge NumPy links the libblas.so.3 shim; resolve it to the backend."""
    lib = pathlib.Path(sys.prefix) / "lib" / "libblas.so.3"
    try:
        return lib.resolve().name
    except OSError:
        return "unknown BLAS"


def time_numpy(workload, m, n, k, warmup, reps):
    ins = tc.make_inputs(workload, m, n, k)
    out = np.empty((m, n), dtype=np.float32)
    if workload == "add":
        f = lambda: np.add(ins["a"], ins["b"], out=out)
    elif workload == "relu":
        f = lambda: np.maximum(ins["a"], np.float32(0), out=out)
    elif workload == "matmul":
        f = lambda: np.matmul(ins["a"], ins["b"], out=out)
    else:
        def f():
            np.matmul(ins["a"], ins["b"], out=out)
            np.add(out, ins["bias"], out=out)
            np.maximum(out, np.float32(0), out=out)
    for _ in range(warmup):
        f()
    ts = []
    for _ in range(reps):
        t0 = time.perf_counter_ns()
        f()
        ts.append(time.perf_counter_ns() - t0)
    ts = np.array(ts, dtype=np.float64)
    return {"median_ns": float(np.median(ts)), "min_ns": float(ts.min()),
            "std_ns": float(ts.std(ddof=1))}


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--csv", required=True)
    ap.add_argument("--tag", required=True)
    ap.add_argument("--variant", action="append", default=[])
    ap.add_argument("--workloads", default="add,relu,matmul,mbr")
    ap.add_argument("--shapes", default="", help="override: MxN or MxNxK, comma separated")
    ap.add_argument("--warmup", type=int, default=10)
    ap.add_argument("--reps", type=int, default=100)
    ap.add_argument("--numpy", action="store_true")
    ap.add_argument("--check-only", action="store_true")
    args = ap.parse_args()

    variants = [v.split("=", 1) for v in (args.variant or ["baseline="])]
    workloads = args.workloads.split(",")
    base = provenance.common()
    device = provenance.cpu_model()
    provenance.save_lscpu(pathlib.Path(args.csv).parent)
    out = None if args.check_only else provenance.CsvWriter(args.csv)
    failures = 0

    for workload in workloads:
        shapes = shapes_for(workload)
        if args.shapes:
            shapes = []
            for s in args.shapes.split(","):
                d = [int(x) for x in s.split("x")]
                shapes.append((d[0], d[1], d[2] if len(d) > 2 else None))
        for m, n, k in shapes:
            metric, work = tc.flops_or_bytes(workload, m, n, k)
            for name, opts in variants:
                kdir = tc.compile_kernel(workload, m, n, k, opts, tag=f"{args.tag}/{name}")
                chk = tc.check(workload, m, n, k, kdir)
                status = "PASS" if chk["pass"] else "FAIL"
                print(f"[{status}] {name:>14} {workload:>6} {shape_str(m, n, k):>14} "
                      f"err/bound={chk['err_over_bound']:.3g} max_abs={chk['max_abs_err']:.3g}",
                      flush=True)
                if not chk["pass"]:
                    failures += 1
                    continue
                if out is None:
                    continue
                r = tc.bench(workload, m, n, k, kdir, args.warmup, args.reps)
                med_s = r["median_ns"] * 1e-9
                out.row(**base, device=device, workload=workload,
                        shape=shape_str(m, n, k), dtype="f32",
                        pipeline=f"tforge-cpu-pipeline{{{opts}}}", params=name,
                        threads=r["threads"], warmup=r["warmup"], reps=r["reps"],
                        median_ms=r["median_ns"] * 1e-6, min_ms=r["min_ns"] * 1e-6,
                        std_ms=r["std_ns"] * 1e-6, metric=metric,
                        metric_value=work / med_s * 1e-9, sm_clock_median_mhz="",
                        clock_adjusted_metric="", alloc_bytes_per_call=r["alloc_bytes_per_call"],
                        correctness=f"err/bound={chk['err_over_bound']:.3g}",
                        notes=f"pinned cpu {r['cpu']}; opt -O3, llc -O3 -mcpu=native")
                print(f"        median {r['median_ns'] * 1e-6:.4f} ms  "
                      f"{work / med_s * 1e-9:.2f} {metric}  alloc {r['alloc_bytes_per_call']} B",
                      flush=True)
            if args.numpy and out is not None:
                r = time_numpy(workload, m, n, k, args.warmup, args.reps)
                med_s = r["median_ns"] * 1e-9
                out.row(**base, device=device, workload=workload, shape=shape_str(m, n, k),
                        dtype="f32", pipeline=f"numpy {np.__version__} ({numpy_blas()})",
                        params="numpy", threads=1, warmup=args.warmup, reps=args.reps,
                        median_ms=r["median_ns"] * 1e-6, min_ms=r["min_ns"] * 1e-6,
                        std_ms=r["std_ns"] * 1e-6, metric=metric,
                        metric_value=work / med_s * 1e-9, sm_clock_median_mhz="",
                        clock_adjusted_metric="", alloc_bytes_per_call="",
                        correctness="reference", notes="OPENBLAS_NUM_THREADS=1; not pinned")
                print(f"        numpy  {r['median_ns'] * 1e-6:.4f} ms  "
                      f"{work / med_s * 1e-9:.2f} {metric}", flush=True)
    print(f"failures: {failures}")
    return 1 if failures else 0


if __name__ == "__main__":
    sys.exit(main())
