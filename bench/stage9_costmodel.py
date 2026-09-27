#!/usr/bin/env python3
"""Stage 9: analytical cost model versus empirical autotuning, fused mbr on GPU.

For each shape:
  1. compile every configuration of costmodel.config_space() (8 in parallel);
     configurations that fail to compile are recorded and excluded,
  2. cost model: read registers/shared memory/occupancy (--info-only) and
     predict the time of each configuration; the model's pick is the minimum,
  3. autotuner: check and time every configuration (10 warm-up, 100 reps),
     the autotuner's pick is the fastest measured,
  4. report the model pick's measured performance relative to the best, raw and
     clock-adjusted (% of FP32 peak at each run's median SM clock).
"""

import argparse
import concurrent.futures as cf
import csv
import pathlib
import sys
import tempfile
import time

sys.path.insert(0, str(pathlib.Path(__file__).resolve().parent.parent / "python"))
import numpy as np  # noqa: E402

import costmodel as cm  # noqa: E402
import provenance  # noqa: E402
import tforge_cpu as tc  # noqa: E402
import tforge_gpu as tg  # noqa: E402

SHAPES = [(1024, 1024, 1024), (2048, 2048, 2048), (4096, 4096, 4096), (1536, 1536, 1536),
          (2560, 2560, 2560), (1000, 1000, 1000), (777, 1111, 333), (3000, 2000, 1000)]


def spearman(x, y):
    rx = np.argsort(np.argsort(x))
    ry = np.argsort(np.argsort(y))
    return float(np.corrcoef(rx, ry)[0, 1])


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--csv", default="results/gpu/stage9_autotune.csv")
    ap.add_argument("--summary", default="results/gpu/stage9_summary.csv")
    ap.add_argument("--shapes", default="")
    ap.add_argument("--jobs", type=int, default=8)
    args = ap.parse_args()
    shapes = SHAPES
    if args.shapes:
        shapes = [tuple(int(v) for v in s.split("x")) for s in args.shapes.split(",")]
    base = provenance.common()
    out = provenance.CsvWriter(args.csv)
    summ_path = pathlib.Path(args.summary)
    new = not summ_path.exists()
    summ = open(summ_path, "a", newline="")
    sw = csv.writer(summ)
    if new:
        sw.writerow(["commit", "job_id", "date", "shape", "configs_total", "configs_compiled",
                     "model_pick", "model_pick_ms", "model_pick_pct", "best", "best_ms", "best_pct",
                     "ratio_raw", "ratio_clock_adjusted", "model_rank_of_best", "measured_rank_of_model_pick",
                     "spearman_pred_vs_measured", "model_cost_s", "autotune_cost_s"])
    space = cm.config_space()
    wl = "mbr"
    for m, n, k in shapes:
        tag = f"stage9/{m}x{n}x{k}"
        t0 = time.time()

        def build(cfg):
            try:
                d, launch = tg.compile_kernel(wl, m, n, k, cm.options(cfg), tag=f"{tag}/{cm.name(cfg)}")
                return cfg, d, launch, None
            except Exception as e:  # noqa: BLE001 - recorded, config excluded
                return cfg, None, None, str(e).splitlines()[0][:200]

        with cf.ThreadPoolExecutor(args.jobs) as ex:
            built = list(ex.map(build, space))
        compiled = [(c, d, l) for c, d, l, err in built if err is None]
        failed = [(c, err) for c, _, _, err in built if err is not None]
        t_compile = time.time() - t0
        for c, err in failed:
            print(f"  compile failed {cm.name(c)}: {err}", flush=True)

        # Cost model: occupancy API + formula.
        t1 = time.time()
        preds = {}
        for c, d, l in compiled:
            inf = tg.info(wl, m, n, k, d, l)
            preds[c] = (cm.predict(c, l["padded"], inf), inf)
        t_model = time.time() - t1
        pick = min(preds, key=lambda c: preds[c][0]["pred_ms"])

        # Autotuner: check and time everything, using one FP64 reference.
        ins = tc.make_inputs(wl, m, n, k)
        a64, b64, bias64 = (ins[x].astype(np.float64) for x in ("a", "b", "bias"))
        ref = np.maximum(a64 @ b64 + bias64, 0.0)
        mag = np.abs(a64) @ np.abs(b64) + np.abs(bias64)
        gamma = (k + 1) * tc.F32_EPS / (1 - (k + 1) * tc.F32_EPS)
        bound = gamma * mag + np.finfo(np.float32).tiny
        t2 = time.time()
        meas = {}
        with tempfile.TemporaryDirectory() as td:
            for name_, arr in ins.items():
                arr.tofile(f"{td}/{name_}.bin")
            for c, d, l in compiled:
                tg.run(tg._bench_cmd(wl, m, n, k, d, l) + ["--warmup", 0, "--reps", 1, "--in-dir", td,
                                                          "--out", f"{td}/out.bin"])
                got = np.fromfile(f"{td}/out.bin", dtype=np.float32).reshape(m, n).astype(np.float64)
                eob = float(np.nanmax(np.abs(got - ref) / bound))
                ok = not np.isnan(got).any() and eob <= 1.0
                if not ok:
                    print(f"  [FAIL] {cm.name(c)} err/bound={eob}", flush=True)
                    continue
                r = tg.bench(wl, m, n, k, d, l)
                gf = 2.0 * m * n * k / (r["median_ms"] * 1e-3) / 1e9
                pct = 100.0 * gf / tg.fp32_peak_gflops(r["sm_clock_median_mhz"])
                meas[c] = (r, gf, pct, eob)
                p, inf = preds[c]
                out.row(**base, device=r["gpu"], workload=wl, shape=f"{m}x{n}x{k}", dtype="f32",
                        pipeline=f"tforge-gpu-pipeline{{{cm.options(c)}}}",
                        params=(f"{cm.name(c)}; grid={r['grid']} block={r['block']} padded={r['padded']}; "
                                f"regs={inf['regs']} smem={inf['static_smem']} blocks/SM={inf['blocks_per_sm']} "
                                f"occ={inf['theo_occupancy']}"),
                        threads="", warmup=r["warmup"], reps=r["reps"], median_ms=r["median_ms"],
                        min_ms=r["min_ms"], std_ms=r["std_ms"], metric="GFLOP/s", metric_value=gf,
                        sm_clock_median_mhz=r["sm_clock_median_mhz"],
                        clock_adjusted_metric=f"{pct:.2f}% of FP32 peak at median clock",
                        alloc_bytes_per_call="", correctness=f"err/bound={eob:.3g}",
                        notes=(f"model: pred_ms={p['pred_ms']:.4f} waves={p['waves']} resident={p['resident']} "
                               f"bound={p['bound']} fma_step={p['fma_step']:.0f} lds_step={p['lds_step']:.0f} "
                               f"latency_exposed={int(p['latency_exposed'])}"))
        t_tune = time.time() - t2
        best = min(meas, key=lambda c: meas[c][0]["median_ms"])
        ok_cfgs = list(meas)
        pred_ms = [preds[c][0]["pred_ms"] for c in ok_cfgs]
        meas_ms = [meas[c][0]["median_ms"] for c in ok_cfgs]
        rho = spearman(pred_ms, meas_ms)
        order_pred = sorted(ok_cfgs, key=lambda c: preds[c][0]["pred_ms"])
        order_meas = sorted(ok_cfgs, key=lambda c: meas[c][0]["median_ms"])
        if pick not in meas:
            print(f"  model pick {cm.name(pick)} failed correctness; using next prediction", flush=True)
            pick = order_pred[0]
        rp, gp, pp, _ = meas[pick]
        rb, gb, pb, _ = meas[best]
        sw.writerow([base["commit"], base["job_id"], base["date"], f"{m}x{n}x{k}", len(space), len(compiled),
                     cm.name(pick), f"{rp['median_ms']:.6f}", f"{pp:.2f}", cm.name(best), f"{rb['median_ms']:.6f}",
                     f"{pb:.2f}", f"{rb['median_ms'] / rp['median_ms']:.3f}", f"{pp / pb:.3f}",
                     order_pred.index(best) + 1, order_meas.index(pick) + 1, f"{rho:.3f}",
                     f"{t_compile + t_model:.1f}", f"{t_compile + t_tune:.1f}"])
        summ.flush()
        print(f"{m}x{n}x{k}: model {cm.name(pick)} {rp['median_ms']:.4f} ms ({pp:.1f}%), "
              f"best {cm.name(best)} {rb['median_ms']:.4f} ms ({pb:.1f}%), ratio raw "
              f"{rb['median_ms'] / rp['median_ms']:.3f} clock-adj {pp / pb:.3f}, spearman {rho:.3f}, "
              f"compiled {len(compiled)}/{len(space)}, model {t_compile + t_model:.0f} s, "
              f"autotune {t_compile + t_tune:.0f} s", flush=True)
    return 0


if __name__ == "__main__":
    sys.exit(main())
