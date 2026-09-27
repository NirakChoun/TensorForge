#!/usr/bin/env python3
"""Pivot a GPU results CSV: rows = variant, columns = shape.

Cells show GFLOP/s and, in parentheses, % of FP32 peak at the median SM clock.
  python3 python/gpu_summary.py results/gpu/stage7.csv [--workload mbr] [--ms]
"""

import argparse
import csv
import re
from collections import OrderedDict


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("csv")
    ap.add_argument("--workload", default="")
    ap.add_argument("--ms", action="store_true", help="show median ms instead")
    args = ap.parse_args()
    rows = list(csv.DictReader(open(args.csv)))
    if args.workload:
        rows = [r for r in rows if r["workload"] == args.workload]
    name = lambda r: r["params"].split(";")[0].strip()
    shapes = list(OrderedDict.fromkeys(r["shape"] for r in rows))
    variants = list(OrderedDict.fromkeys(name(r) for r in rows))
    cell = {}
    for r in rows:
        pct = re.match(r"([0-9.]+)%", r["clock_adjusted_metric"])
        if args.ms:
            cell[(name(r), r["shape"])] = f"{float(r['median_ms']):.4f}"
        else:
            cell[(name(r), r["shape"])] = (f"{float(r['metric_value']):.0f} ({pct.group(1)}%)"
                                           if pct else f"{float(r['metric_value']):.0f}")
    print("| variant | " + " | ".join(shapes) + " |")
    print("|---|" + "---|" * len(shapes))
    for v in variants:
        print(f"| {v} | " + " | ".join(cell.get((v, s), "") for s in shapes) + " |")
    clocks = sorted({r["sm_clock_median_mhz"] for r in rows})
    print(f"\nmedian SM clocks seen: {', '.join(clocks)} MHz")


if __name__ == "__main__":
    main()
