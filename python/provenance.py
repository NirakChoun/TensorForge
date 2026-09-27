"""Provenance fields shared by every results CSV row (brief, Section 4 rule 3)."""

import csv
import datetime
import os
import pathlib
import subprocess

ROOT = pathlib.Path(__file__).resolve().parent.parent

FIELDS = [
    "commit", "mlir_llvm_version", "cuda_version", "device", "job_id", "date",
    "workload", "shape", "dtype", "pipeline", "params", "threads", "warmup", "reps",
    "median_ms", "min_ms", "std_ms", "metric", "metric_value", "sm_clock_median_mhz",
    "clock_adjusted_metric", "alloc_bytes_per_call", "correctness", "notes",
]


def _sh(cmd):
    try:
        return subprocess.run(cmd, shell=True, capture_output=True, text=True).stdout.strip()
    except OSError:
        return ""


def common():
    dirty = _sh(f"git -C {ROOT} status --porcelain --untracked-files=no")
    commit = _sh(f"git -C {ROOT} rev-parse --short HEAD") + ("-dirty" if dirty else "")
    mlir = _sh("mlir-opt --version | grep -o 'LLVM version [0-9.]*'").replace("LLVM version ", "")
    cuda = _sh("nvcc --version | grep -o 'release [0-9.]*'").replace("release ", "")
    return {
        "commit": commit,
        "mlir_llvm_version": mlir,
        "cuda_version": cuda,
        "job_id": os.environ.get("SLURM_JOB_ID", "none"),
        "date": datetime.datetime.now().astimezone().isoformat(timespec="seconds"),
    }


def cpu_model():
    return _sh("lscpu | grep -m1 'Model name' | sed 's/Model name:[ ]*//'")


def save_lscpu(outdir):
    outdir = pathlib.Path(outdir)
    outdir.mkdir(parents=True, exist_ok=True)
    job = os.environ.get("SLURM_JOB_ID", "none")
    p = outdir / f"lscpu_{job}.txt"
    p.write_text(_sh("hostname") + "\n" + _sh("lscpu") + "\n")
    return p


class CsvWriter:
    """Appends rows to a CSV, writing the header only for a new file."""

    def __init__(self, path):
        self.path = pathlib.Path(path)
        self.path.parent.mkdir(parents=True, exist_ok=True)
        new = not self.path.exists()
        self.f = open(self.path, "a", newline="")
        self.w = csv.DictWriter(self.f, fieldnames=FIELDS)
        if new:
            self.w.writeheader()

    def row(self, **kw):
        missing = set(kw) - set(FIELDS)
        if missing:
            raise KeyError(missing)
        self.w.writerow(kw)
        self.f.flush()
