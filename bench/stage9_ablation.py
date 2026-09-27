#!/usr/bin/env python3
"""Stage 9 ablation on the default GPU pipeline for relu(A @ B + bias).

  baseline     unfused: three naive kernels (matmul, bias_add, relu), one output
               per thread, 16x16 blocks; time = sum of the three medians, each
               kernel checked on its own (matmul against the FP64 bound,
               bias_add and relu bit-exact against NumPy)
  +fusion      one naive fused kernel (Stage 7 configuration)
  +tiling      128x64 blocks, 8x4 per thread, K step 16 (no shared memory, not vectorized)
  +promotion   + A/B tiles staged in shared memory
  +vectorize   + vectorized thread tiles and copies, 128-bit accesses (the default)
"""

import argparse
import pathlib
import sys

sys.path.insert(0, str(pathlib.Path(__file__).resolve().parent.parent / "python"))

import provenance  # noqa: E402
import tforge_gpu as tg  # noqa: E402

SHAPES = [(1024, 1024, 1024), (2048, 2048, 2048), (4096, 4096, 4096), (777, 1111, 333)]
NAIVE = "block-tile=16,16 thread-tile=1,1"
TILED = "block-tile=128,64 thread-tile=8,4 tile-k=16"
STEPS = [("+fusion", NAIVE), ("+tiling", TILED), ("+promotion", TILED + " promote=1"),
         ("+vectorize", TILED + " promote=1 vectorize=1")]


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--csv", default="results/gpu/stage9_ablation.csv")
    args = ap.parse_args()
    base = provenance.common()
    out = provenance.CsvWriter(args.csv)
    failures = 0

    def record(step, workload, m, n, k, opts, r, chk, note=""):
        gf = 2.0 * m * n * k / (r["median_ms"] * 1e-3) / 1e9
        pct = 100.0 * gf / tg.fp32_peak_gflops(r["sm_clock_median_mhz"])
        out.row(**base, device=r["gpu"], workload=workload, shape=f"{m}x{n}x{k}", dtype="f32",
                pipeline=f"tforge-gpu-pipeline{{{opts}}}",
                params=f"{step}; grid={r['grid']} block={r['block']}; regs={r['regs']} smem={r['static_smem']}",
                threads="", warmup=r["warmup"], reps=r["reps"], median_ms=r["median_ms"], min_ms=r["min_ms"],
                std_ms=r["std_ms"], metric="GFLOP/s (of the full mbr)", metric_value=gf,
                sm_clock_median_mhz=r["sm_clock_median_mhz"],
                clock_adjusted_metric=f"{pct:.2f}% of FP32 peak at median clock", alloc_bytes_per_call="",
                correctness=f"err/bound={chk['err_over_bound']:.3g}", notes=note)
        return gf, pct

    for m, n, k in SHAPES:
        # Baseline: three kernels.
        parts, total_ms, clocks, ok = [], 0.0, [], True
        for wl, kk in (("matmul", k), ("bias_add", None), ("relu", None)):
            d, launch = tg.compile_kernel(wl, m, n, kk, NAIVE, tag=f"stage9abl/baseline")
            chk, _ = tg.check(wl, m, n, kk, d, launch)
            ok &= chk["pass"]
            r = tg.bench(wl, m, n, kk, d, launch)
            parts.append((wl, r, chk))
            total_ms += r["median_ms"]
            clocks.append(r["sm_clock_median_mhz"])
        if not ok:
            failures += 1
            print(f"[FAIL] baseline {m}x{n}x{k}", flush=True)
        for wl, r, chk in parts:
            record(f"baseline part: {wl}", wl, m, n, k, NAIVE, r, chk,
                   note="one of three unfused kernels; metric uses the mbr FLOP count")
        gf = 2.0 * m * n * k / (total_ms * 1e-3) / 1e9
        clk = sorted(clocks)[1]
        pct = 100.0 * gf / tg.fp32_peak_gflops(clk)
        r0 = parts[0][1]
        out.row(**base, device=r0["gpu"], workload="mbr", shape=f"{m}x{n}x{k}", dtype="f32",
                pipeline=f"tforge-gpu-pipeline{{{NAIVE}}} x3 kernels (matmul, bias_add, relu)",
                params="baseline (unfused); sum of three kernel medians", threads="", warmup=10, reps=100,
                median_ms=total_ms, min_ms=sum(p[1]["min_ms"] for p in parts),
                std_ms="", metric="GFLOP/s", metric_value=gf, sm_clock_median_mhz=clk,
                clock_adjusted_metric=f"{pct:.2f}% of FP32 peak at median clock (median of 3 kernel clocks)",
                alloc_bytes_per_call="", correctness="each kernel checked; see baseline part rows",
                notes="time excludes launch gaps between the three kernels")
        print(f"baseline {m}x{n}x{k}: {total_ms:.4f} ms {gf:.0f} GFLOP/s", flush=True)
        for step, opts in STEPS:
            d, launch = tg.compile_kernel("mbr", m, n, k, opts, tag=f"stage9abl/{step[1:]}")
            chk, _ = tg.check("mbr", m, n, k, d, launch)
            if not chk["pass"]:
                failures += 1
                print(f"[FAIL] {step} {m}x{n}x{k}", flush=True)
                continue
            r = tg.bench("mbr", m, n, k, d, launch)
            gf, pct = record(step, "mbr", m, n, k, opts, r, chk)
            print(f"{step} {m}x{n}x{k}: {r['median_ms']:.4f} ms {gf:.0f} GFLOP/s {pct:.1f}%", flush=True)
    print(f"failures: {failures}")
    return 1 if failures else 0


if __name__ == "__main__":
    sys.exit(main())
