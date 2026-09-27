#!/usr/bin/env python3
"""Pivot a sweep CSV: rows = variant (params), columns = shape, cells = metric.

  python3 python/sweep_summary.py results/cpu/stage6_sweep.csv [--value metric_value]
Also prints the best variant per shape.
"""

import argparse
import csv
from collections import OrderedDict


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("csv")
    ap.add_argument("--value", default="metric_value")
    ap.add_argument("--workload", default="")
    args = ap.parse_args()
    rows = list(csv.DictReader(open(args.csv)))
    if args.workload:
        rows = [r for r in rows if r["workload"] == args.workload]
    shapes = list(OrderedDict.fromkeys(r["shape"] for r in rows))
    variants = list(OrderedDict.fromkeys(r["params"] for r in rows))
    cell = {(r["params"], r["shape"]): float(r[args.value]) for r in rows}
    print("| variant | " + " | ".join(shapes) + " |")
    print("|---|" + "---|" * len(shapes))
    for v in variants:
        vals = [cell.get((v, s)) for s in shapes]
        print(f"| {v} | " + " | ".join("" if x is None else f"{x:.1f}" for x in vals) + " |")
    print()
    for s in shapes:
        best = max((v for v in variants if (v, s) in cell), key=lambda v: cell[(v, s)])
        print(f"best {s}: {best} {cell[(best, s)]:.1f}")


if __name__ == "__main__":
    main()
