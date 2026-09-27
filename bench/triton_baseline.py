#!/usr/bin/env python3
"""Triton baseline for relu(A @ B + bias) (fused epilogue) and plain matmul.

Run with KernelForge's virtual environment (Triton 3.8, torch), used read-only:
  ~/KernelForge/.venv/bin/python bench/triton_baseline.py --csv results/gpu/stage8_triton.csv

The autotuning search space is KernelForge's MATMUL_SPACE (imported from
~/KernelForge/python/triton_kernels.py, not modified), so this matches the
Triton configuration KernelForge measured. tl.dot uses input_precision="ieee"
(FP32, not TF32). Timing: 10 warm-up + 100 reps with CUDA events after
autotuning, median; SM clock sampled by nvidia-smi every 50 ms during the reps.
Correctness: FP64 reference (torch, GPU) with the gamma_{K+1} bound used for
TensorForge, and max difference from cuBLAS FP32 (torch.matmul, TF32 off).
"""

import argparse
import os
import pathlib
import statistics
import subprocess
import sys

import torch
import triton
import triton.language as tl

ROOT = pathlib.Path(__file__).resolve().parent.parent
sys.path.insert(0, str(ROOT / "python"))
sys.path.insert(0, os.path.expanduser("~/KernelForge/python"))
import provenance  # noqa: E402
from triton_kernels import MATMUL_SPACE  # noqa: E402  (KernelForge, read-only)

torch.backends.cuda.matmul.allow_tf32 = False
F32_EPS = 2.0 ** -24
SHAPES = [(256, 256, 256), (512, 512, 512), (1024, 1024, 1024), (2048, 2048, 2048),
          (4096, 4096, 4096), (1000, 1000, 1000), (777, 1111, 333)]


def configs():
    return [triton.Config({"BM": bm, "BN": bn, "BK": bk, "GROUP_M": 8}, num_warps=w, num_stages=s)
            for bm, bn, bk, w, s in MATMUL_SPACE]


@triton.autotune(configs=configs(), key=["M", "N", "K", "EPILOGUE"])
@triton.jit
def mbr_kernel(a_ptr, b_ptr, bias_ptr, c_ptr, M, N, K, stride_am, stride_ak, stride_bk,
               stride_bn, stride_cm, stride_cn, EPILOGUE: tl.constexpr, BM: tl.constexpr,
               BN: tl.constexpr, BK: tl.constexpr, GROUP_M: tl.constexpr):
    pid = tl.program_id(0)
    num_pid_m = tl.cdiv(M, BM)
    num_pid_n = tl.cdiv(N, BN)
    num_in_group = GROUP_M * num_pid_n
    group = pid // num_in_group
    first_m = group * GROUP_M
    group_m = tl.minimum(num_pid_m - first_m, GROUP_M)
    pid_m = first_m + ((pid % num_in_group) % group_m)
    pid_n = (pid % num_in_group) // group_m
    offs_m = pid_m * BM + tl.arange(0, BM)
    offs_n = pid_n * BN + tl.arange(0, BN)
    offs_k = tl.arange(0, BK)
    a_ptrs = a_ptr + offs_m[:, None] * stride_am + offs_k[None, :] * stride_ak
    b_ptrs = b_ptr + offs_k[:, None] * stride_bk + offs_n[None, :] * stride_bn
    acc = tl.zeros((BM, BN), dtype=tl.float32)
    for k in range(0, tl.cdiv(K, BK)):
        k_left = K - k * BK
        a = tl.load(a_ptrs, mask=(offs_m[:, None] < M) & (offs_k[None, :] < k_left), other=0.0)
        b = tl.load(b_ptrs, mask=(offs_k[:, None] < k_left) & (offs_n[None, :] < N), other=0.0)
        acc = tl.dot(a, b, acc, input_precision="ieee")
        a_ptrs += BK * stride_ak
        b_ptrs += BK * stride_bk
    if EPILOGUE:
        bias = tl.load(bias_ptr + offs_n, mask=offs_n < N, other=0.0)
        acc = tl.maximum(acc + bias[None, :], 0.0)
    c_ptrs = c_ptr + offs_m[:, None] * stride_cm + offs_n[None, :] * stride_cn
    tl.store(c_ptrs, acc, mask=(offs_m[:, None] < M) & (offs_n[None, :] < N))


def launch(a, b, bias, c, epilogue):
    M, K = a.shape
    N = b.shape[1]
    grid = lambda meta: (triton.cdiv(M, meta["BM"]) * triton.cdiv(N, meta["BN"]),)
    mbr_kernel[grid](a, b, bias, c, M, N, K, a.stride(0), a.stride(1), b.stride(0), b.stride(1),
                     c.stride(0), c.stride(1), EPILOGUE=epilogue)


class ClockSampler:
    def __enter__(self):
        self.p = subprocess.Popen(["nvidia-smi", "--query-gpu=clocks.sm", "--format=csv,noheader,nounits",
                                   "-lms", "50"], stdout=subprocess.PIPE, text=True)
        return self

    def __exit__(self, *exc):
        self.p.terminate()
        out, _ = self.p.communicate()
        self.samples = [float(x) for x in out.split() if x.strip().replace(".", "").isdigit()]


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--csv", required=True)
    ap.add_argument("--workloads", default="matmul,mbr")
    ap.add_argument("--warmup", type=int, default=10)
    ap.add_argument("--reps", type=int, default=100)
    args = ap.parse_args()
    base = provenance.common()
    out = provenance.CsvWriter(args.csv)
    dev = torch.cuda.get_device_name(0)
    failures = 0
    for workload in args.workloads.split(","):
        epi = workload == "mbr"
        for m, n, k in SHAPES:
            g = torch.Generator(device="cuda").manual_seed(1234)
            a = torch.rand(m, k, device="cuda", generator=g) * 2 - 1
            b = torch.rand(k, n, device="cuda", generator=g) * 2 - 1
            bias = torch.rand(n, device="cuda", generator=g) * 2 - 1
            c = torch.full((m, n), float("nan"), device="cuda")
            launch(a, b, bias, c, epi)  # autotunes on first call
            torch.cuda.synchronize()
            ref = a.double() @ b.double()
            mag = a.double().abs() @ b.double().abs()
            steps = k
            cublas = a @ b
            if epi:
                ref = torch.clamp(ref + bias.double(), min=0.0)
                mag = mag + bias.double().abs()
                steps = k + 1
                cublas = torch.clamp(cublas + bias, min=0.0)
            gamma = steps * F32_EPS / (1 - steps * F32_EPS)
            err = (c.double() - ref).abs()
            eob = float((err / (gamma * mag + 1.17549435e-38)).max())
            diff = float((c - cublas).abs().max())
            ok = bool(torch.isfinite(c).all()) and eob <= 1.0
            print(f"[{'PASS' if ok else 'FAIL'}] triton {workload} {m}x{n}x{k} err/bound={eob:.3g} "
                  f"max|x-cublas|={diff:.3g} config={mbr_kernel.best_config}", flush=True)
            if not ok:
                failures += 1
                continue
            for _ in range(args.warmup):
                launch(a, b, bias, c, epi)
            torch.cuda.synchronize()
            ts = []
            with ClockSampler() as clk:
                for _ in range(args.reps):
                    e0, e1 = torch.cuda.Event(enable_timing=True), torch.cuda.Event(enable_timing=True)
                    e0.record()
                    launch(a, b, bias, c, epi)
                    e1.record()
                    e1.synchronize()
                    ts.append(e0.elapsed_time(e1))
            med = statistics.median(ts)
            clock_note = f"clock: median of {len(clk.samples)} nvidia-smi samples (50 ms) during reps"
            if not clk.samples:
                # Runs shorter than one sampling period: read the clock once
                # right after the timed loop, while the GPU is still at its
                # active clock.
                q = subprocess.run(["nvidia-smi", "--query-gpu=clocks.sm", "--format=csv,noheader,nounits"],
                                   capture_output=True, text=True).stdout.split()
                clk.samples = [float(q[0])] if q else []
                clock_note = "clock: one nvidia-smi reading right after the reps (run shorter than 50 ms)"
            clock = statistics.median(clk.samples) if clk.samples else -1
            gflops = 2.0 * m * n * k / (med * 1e-3) / 1e9
            pct = 100.0 * gflops / (188 * 128 * 2 * clock * 1e6 / 1e9) if clock > 0 else float("nan")
            bc = mbr_kernel.best_config
            out.row(**base, device=dev, workload=workload, shape=f"{m}x{n}x{k}", dtype="f32",
                    pipeline=f"triton {triton.__version__} fused epilogue={int(epi)} ieee",
                    params=f"triton; {bc}", threads="", warmup=args.warmup, reps=args.reps,
                    median_ms=med, min_ms=min(ts), std_ms=statistics.stdev(ts), metric="GFLOP/s",
                    metric_value=gflops, sm_clock_median_mhz=clock,
                    clock_adjusted_metric=f"{pct:.2f}% of FP32 peak at median clock",
                    alloc_bytes_per_call="", correctness=f"err/bound={eob:.3g}; max|x-cublas|={diff:.3g}",
                    notes=f"inputs torch uniform[-1,1] seed 1234; {clock_note}")
            print(f"        median {med:.4f} ms {gflops:.1f} GFLOP/s {pct:.1f}% @ {clock:.0f} MHz", flush=True)
    print(f"failures: {failures}")
    return 1 if failures else 0


if __name__ == "__main__":
    sys.exit(main())
