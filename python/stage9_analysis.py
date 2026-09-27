#!/usr/bin/env python3
"""Post-hoc look at the Stage 9 cost model (does not change the model).

For each shape: the model's top 5 and the measured top 5; then, over all
shapes, the mean clock-adjusted efficiency and mean predicted/measured time
ratio per thread tile and per block tile, to show which choices the model
over- or under-rates.
"""

import csv
import re
import statistics
import sys
from collections import defaultdict

path = sys.argv[1] if len(sys.argv) > 1 else "results/gpu/stage9_autotune.csv"
rows = list(csv.DictReader(open(path)))
by_shape = defaultdict(list)
for r in rows:
    name = r["params"].split(";")[0].strip()
    pred = float(re.search(r"pred_ms=([0-9.]+)", r["notes"]).group(1))
    pct = float(re.match(r"([0-9.]+)%", r["clock_adjusted_metric"]).group(1))
    bound = re.search(r"bound=(\w+)", r["notes"]).group(1)
    bps = int(re.search(r"blocks/SM=(\d+)", r["params"]).group(1))
    regs = int(re.search(r"regs=(\d+)", r["params"]).group(1))
    by_shape[r["shape"]].append(dict(name=name, pred=pred, meas=float(r["median_ms"]), pct=pct,
                                     bound=bound, bps=bps, regs=regs))

tile_stats = defaultdict(lambda: defaultdict(list))
for shape, cs in by_shape.items():
    cs_p = sorted(cs, key=lambda c: c["pred"])
    cs_m = sorted(cs, key=lambda c: c["meas"])
    print(f"## {shape}")
    print("model top 5:    " + ", ".join(f"{c['name']} ({c['pct']:.1f}%, pred {c['pred']:.3f})" for c in cs_p[:5]))
    print("measured top 5: " + ", ".join(f"{c['name']} ({c['pct']:.1f}%, pred rank "
                                           f"{cs_p.index(c) + 1})" for c in cs_m[:5]))
    for c in cs:
        t = re.search(r"-t(\d+x\d+)-", c["name"]).group(1)
        b = re.search(r"b(\d+x\d+)-", c["name"]).group(1)
        tile_stats["thread " + t]["pct"].append(c["pct"])
        tile_stats["thread " + t]["ratio"].append(c["pred"] / c["meas"])
        tile_stats["block " + b]["pct"].append(c["pct"])
        tile_stats["block " + b]["ratio"].append(c["pred"] / c["meas"])
        tile_stats["bound " + c["bound"]]["pct"].append(c["pct"])
        tile_stats["bound " + c["bound"]]["ratio"].append(c["pred"] / c["meas"])

print("\n| group | configs | mean % of peak (measured) | mean predicted/measured time |")
print("|---|---|---|---|")
for g in sorted(tile_stats):
    s = tile_stats[g]
    print(f"| {g} | {len(s['pct'])} | {statistics.mean(s['pct']):.1f} | {statistics.mean(s['ratio']):.2f} |")
