#!/usr/bin/env python3
"""Render results CSV rows as a Markdown table for the stage documents.

  python3 python/md_table.py results/cpu/stage4.csv [--workload mbr] [--cols ...]
"""

import argparse
import csv

DEFAULT_COLS = ["workload", "shape", "params", "median_ms", "std_ms", "metric_value",
                "metric", "alloc_bytes_per_call"]


def fmt(v):
    try:
        f = float(v)
    except ValueError:
        return v
    if f == int(f) and abs(f) >= 1000:
        return str(int(f))
    if abs(f) >= 100:
        return f"{f:.1f}"
    if abs(f) >= 1:
        return f"{f:.2f}"
    return f"{f:.4f}"


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("csv")
    ap.add_argument("--workload", default="")
    ap.add_argument("--cols", default=",".join(DEFAULT_COLS))
    args = ap.parse_args()
    cols = args.cols.split(",")
    rows = list(csv.DictReader(open(args.csv)))
    if args.workload:
        rows = [r for r in rows if r["workload"] in args.workload.split(",")]
    print("| " + " | ".join(cols) + " |")
    print("|" + "---|" * len(cols))
    for r in rows:
        print("| " + " | ".join(fmt(r.get(c, "")) for c in cols) + " |")


if __name__ == "__main__":
    main()
