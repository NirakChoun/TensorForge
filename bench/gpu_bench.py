#!/usr/bin/env python3
"""GPU correctness + timing driver for TensorForge kernels (and cuBLAS).

Every (variant, workload, shape) is compiled and checked before timing:
  - pass/fail: FP64 reference with the gamma_{K+1} bound (same as the CPU check)
  - reported: max |kernel - cuBLAS| on the same inputs
Timing: 10 warm-up + 100 reps (CUDA events), median; SM clock sampled per rep
through NVML; clock-adjusted metric = % of FP32 peak at the median SM clock
(188 SMs x 128 lanes x 2 x clock), KernelForge's convention.

  python3 bench/gpu_bench.py --csv results/gpu/stage7.csv --tag stage7 \
      --variant naive-16x16="block-tile=16,16 thread-tile=1,1" --cublas
"""

import argparse
import pathlib
import sys

sys.path.insert(0, str(pathlib.Path(__file__).resolve().parent.parent / "python"))
import numpy as np  # noqa: E402

import provenance  # noqa: E402
import tforge_gpu as tg  # noqa: E402

SHAPES = [(256, 256, 256), (512, 512, 512), (1024, 1024, 1024), (2048, 2048, 2048),
          (4096, 4096, 4096), (1000, 1000, 1000), (777, 1111, 333)]


def shape_str(m, n, k):
    return f"{m}x{n}x{k}"


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--csv", required=True)
    ap.add_argument("--tag", required=True)
    ap.add_argument("--variant", action="append", default=[])
    ap.add_argument("--workloads", default="matmul,mbr")
    ap.add_argument("--shapes", default="")
    ap.add_argument("--warmup", type=int, default=10)
    ap.add_argument("--reps", type=int, default=100)
    ap.add_argument("--flush", action="store_true")
    ap.add_argument("--cublas", action="store_true", help="also time cuBLAS (+ separate epilogue)")
    ap.add_argument("--check-only", action="store_true")
    args = ap.parse_args()

    variants = [v.split("=", 1) for v in args.variant]
    shapes = SHAPES
    if args.shapes:
        shapes = [tuple(int(x) for x in s.split("x")) for s in args.shapes.split(",")]
    base = provenance.common()
    out = None if args.check_only else provenance.CsvWriter(args.csv)
    failures = 0

    for workload in args.workloads.split(","):
        for m, n, k in shapes:
            flops = 2.0 * m * n * k
            _, ref_cublas = tg.check(workload, m, n, k, mode="cublas")
            rows = [(name, opts, "kernel") for name, opts in variants]
            if args.cublas:
                rows.append(("cublas", "", "cublas"))
            for name, opts, mode in rows:
                kdir = launch = None
                res_info = {}
                if mode == "kernel":
                    kdir, launch = tg.compile_kernel(workload, m, n, k, opts, tag=f"{args.tag}/{name}")
                    res_info = tg.ptxas_resources(kdir)
                chk, got = tg.check(workload, m, n, k, kdir, launch, mode)
                diff = float(np.nanmax(np.abs(got.astype(np.float64) - ref_cublas)))
                status = "PASS" if chk["pass"] else "FAIL"
                print(f"[{status}] {name:>22} {workload:>6} {shape_str(m, n, k):>16} "
                      f"err/bound={chk['err_over_bound']:.3g} max|x-cublas|={diff:.3g}", flush=True)
                if not chk["pass"]:
                    failures += 1
                    continue
                if out is None:
                    continue
                r = tg.bench(workload, m, n, k, kdir, launch, mode, args.warmup, args.reps, args.flush)
                gflops = flops / (r["median_ms"] * 1e-3) / 1e9
                clk = r["sm_clock_median_mhz"]
                pct = 100.0 * gflops / tg.fp32_peak_gflops(clk) if clk > 0 else float("nan")
                launch_str = f"grid={r['grid']} block={r['block']}"
                res = (f"regs={r['regs']} local={r['local_bytes']} smem={r['static_smem']} "
                       f"blocks/SM={r['blocks_per_sm']} occ={r['theo_occupancy']}")
                if res_info:
                    res += f" spill_st={res_info['spill_stores']} spill_ld={res_info['spill_loads']}"
                pipeline = (f"tforge-gpu-pipeline{{{opts}}}" if mode == "kernel" else
                            "cublasSgemm FP32 default math" + (" + bias_relu kernel" if workload == "mbr" else ""))
                out.row(**base, device=r["gpu"], workload=workload, shape=shape_str(m, n, k),
                        dtype="f32", pipeline=pipeline, params=f"{name}; {launch_str}; {res}",
                        threads="", warmup=r["warmup"], reps=r["reps"], median_ms=r["median_ms"],
                        min_ms=r["min_ms"], std_ms=r["std_ms"], metric="GFLOP/s",
                        metric_value=gflops, sm_clock_median_mhz=clk,
                        clock_adjusted_metric=f"{pct:.2f}% of FP32 peak at median clock",
                        alloc_bytes_per_call="",
                        correctness=f"err/bound={chk['err_over_bound']:.3g}; max|x-cublas|={diff:.3g}",
                        notes=(f"l2_flush={r['l2_flush']}; sm_clock {r['sm_clock_min_mhz']}-"
                               f"{r['sm_clock_max_mhz']} MHz; power {r['power_median_w']} W; "
                               f"driver {r['cuda_driver']}"))
                print(f"        median {r['median_ms']:.4f} ms  {gflops:.1f} GFLOP/s  "
                      f"{pct:.1f}% @ {clk:.0f} MHz  {res}", flush=True)
    print(f"failures: {failures}")
    return 1 if failures else 0


if __name__ == "__main__":
    sys.exit(main())
