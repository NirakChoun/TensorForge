"""Analytical cost model for TensorForge's staged GPU kernel (Stage 9).

The kernel (docs/stage8.md) runs, per block and per K step of size BK:
cooperative 128-bit copies of A[BM x BK] and B[BK x BN] into shared memory,
a barrier, each thread's TM x TN x BK outer products from shared memory, and a
barrier. There is no software pipelining, so a step's global-load latency is
exposed unless other resident blocks on the SM have work to overlap with it.

Inputs per configuration:
  tile sizes (BM, BN, TM, TN, BK), padded problem (Mp, Np, Kp),
  registers and static shared memory (ptxas), and blocks per SM from the CUDA
  occupancy API (tforge-gpu-bench --info-only).

Model, in SM clock cycles:
  blocks           = (Mp / BM) * (Np / BN)
  waves            = ceil(blocks / (SMS * blocks_per_sm))
  resident         = min(blocks_per_sm, ceil(blocks / SMS))      blocks sharing one SM
  fma_step         = BM * BN * BK / FMA_PER_CYCLE                 per block
  lds_step         = threads * BK * (TM + TN) / SMEM_WORDS_PER_CYCLE
  compute_step     = max(fma_step, lds_step)
  step             = resident * compute_step + max(0, LATENCY - (resident - 1) * compute_step)
  cycles           = waves * (Kp / BK) * step
  time             = max(cycles / clock, compulsory_bytes / DRAM_BW)

Arithmetic intensity per block (FLOP per global byte) = 2*BM*BN / (4*(BM + BN)); it
enters through the DRAM floor only, because operand re-reads are L2 hits at these
sizes (the L2 is 128 MiB).

Constants: SMS, FMA_PER_CYCLE, and DRAM_BW are hardware facts from KernelForge
(188 SMs, 128 FP32 lanes per SM, 1530 GB/s achievable DRAM bandwidth). Two are
assumptions, not measurements: SMEM_WORDS_PER_CYCLE = 32 (128 bytes per clock
per SM, the usual NVIDIA shared-memory bandwidth) and LATENCY = 600 cycles for a
global load that misses L1. The model only ranks configurations, so the clock
value cancels; CLOCK_MHZ is the typical median clock seen in Stages 7 and 8.
"""

import math

import os

SMS = int(os.environ.get("TF_GPU_SMS", "188"))
FMA_PER_CYCLE = 128
SMEM_WORDS_PER_CYCLE = 32
LATENCY = 600
DRAM_BW = float(os.environ.get("TF_GPU_DRAM_BW", "1530e9"))
CLOCK_MHZ = 2280


def config_space():
    """The Stage 9 grid: (BM, BN, TM, TN, BK) with 32..1024 threads per block."""
    out = []
    for bm in (32, 64, 128):
        for bn in (32, 64, 128):
            for tm, tn in ((4, 4), (8, 4), (4, 8), (8, 8)):
                for bk in (8, 16, 32):
                    threads = (bm // tm) * (bn // tn)
                    if bm % tm or bn % tn or not 32 <= threads <= 1024:
                        continue
                    out.append((bm, bn, tm, tn, bk))
    return out


def options(cfg):
    bm, bn, tm, tn, bk = cfg
    return (f"block-tile={bm},{bn} thread-tile={tm},{tn} tile-k={bk} "
            f"promote=1 vectorize=1")


def name(cfg):
    bm, bn, tm, tn, bk = cfg
    return f"b{bm}x{bn}-t{tm}x{tn}-k{bk}"


def predict(cfg, padded, info, clock_mhz=CLOCK_MHZ):
    """Predicted time in ms and the terms that produced it."""
    bm, bn, tm, tn, bk = cfg
    mp, np_, kp = padded
    bps = max(1, info["blocks_per_sm"])
    threads = (bm // tm) * (bn // tn)
    blocks = (mp // bm) * (np_ // bn)
    waves = math.ceil(blocks / (SMS * bps))
    resident = min(bps, math.ceil(blocks / SMS))
    fma_step = bm * bn * bk / FMA_PER_CYCLE
    lds_step = threads * bk * (tm + tn) / SMEM_WORDS_PER_CYCLE
    compute_step = max(fma_step, lds_step)
    step = resident * compute_step + max(0.0, LATENCY - (resident - 1) * compute_step)
    cycles = waves * (kp // bk) * step
    t_compute = cycles / (clock_mhz * 1e6)
    t_dram = 4.0 * (mp * kp + kp * np_ + mp * np_) / DRAM_BW
    t = max(t_compute, t_dram)
    return {
        "pred_ms": t * 1e3, "waves": waves, "resident": resident, "blocks": blocks,
        "fma_step": fma_step, "lds_step": lds_step, "bound": "dram" if t_dram > t_compute else
        ("smem" if lds_step > fma_step else "fma"),
        "latency_exposed": max(0.0, LATENCY - (resident - 1) * compute_step) > 0,
        "intensity": 2.0 * bm * bn / (4.0 * (bm + bn)),
    }
