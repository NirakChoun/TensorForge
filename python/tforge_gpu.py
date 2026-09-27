"""Compile, check, and time TensorForge GPU kernels (sm_120).

Compile path, every step kept on disk for inspection:
  input.mlir --tensorforge-opt --tforge-gpu-pipeline--> device.mlir (NVVM + tforge.launch)
  --mlir-translate--> k.ll --opt -O3--> k.opt.ll --llc -O3 -mcpu=sm_120 -fp-contract=fast-->
  k.ptx --ptxas -O3 -v--> k.cubin (ptxas.txt)
  --cuobjdump -sass--> k.sass
"""

import json
import os
import pathlib
import re
import subprocess
import tempfile

import numpy as np

import tforge_cpu as tc  # workload generator, inputs, FP64 reference check

ROOT = tc.ROOT
OPT = tc.OPT
GPU_BENCH = tc.BUILD / "bin" / "tforge-gpu-bench"
ART = tc.ART / "gpu"
SM = "sm_120"
SMS = 188
FP32_LANES_PER_SM = 128  # KernelForge: 24064 CUDA cores / 188 SMs


def fp32_peak_gflops(sm_mhz):
    return SMS * FP32_LANES_PER_SM * 2 * sm_mhz * 1e6 / 1e9


def run(cmd, **kw):
    return tc.run(cmd, **kw)


def parse_launch(device_mlir):
    text = pathlib.Path(device_mlir).read_text()
    m = re.search(r"tforge\.launch = \{(.*?)\}\}?", text)
    if not m:
        raise RuntimeError("no tforge.launch attribute in " + str(device_mlir))
    body = m.group(1)
    arr = lambda key: [int(x) for x in re.search(key + r" = array<i64: ([0-9, ]+)>", body).group(1).split(",")]
    args = re.findall(r'"([^"]+)"', re.search(r"args = \[([^\]]*)\]", body).group(1))
    kernel = re.search(r'kernel = "([^"]+)"', body).group(1)
    return {"kernel": kernel, "grid": arr("grid"), "block": arr("block"), "args": args}


def padded_shape(m, n, k, options):
    """Staged kernels (tile-k set) need M, N, K to be multiples of the block and
    K tiles; returns the padded problem the kernel is compiled for."""
    opts = dict(o.split("=", 1) for o in options.split() if "=" in o)
    tk = int(opts.get("tile-k", "0"))
    if tk <= 0:
        return m, n, k
    bm, bn = (int(x) for x in opts.get("block-tile", "16,16").split(","))
    up = lambda x, t: -(-x // t) * t
    return up(m, bm), up(n, bn), up(k, tk)


def compile_kernel(workload, m, n, k, options="", tag="default"):
    """Compile one GPU kernel. For elementwise workloads k is ignored."""
    d = ART / tag / f"{workload}_{m}x{n}x{k}"
    d.mkdir(parents=True, exist_ok=True)
    pm, pn, pk = padded_shape(m, n, k, options)
    (d / "input.mlir").write_text(tc.gen_mlir(workload, pm, pn, pk if workload in ("matmul", "mbr") else None))
    flag = f"--tforge-gpu-pipeline={options}" if options else "--tforge-gpu-pipeline"
    run([OPT, d / "input.mlir", flag, "-o", d / "device.mlir"])
    run(["mlir-translate", "--mlir-to-llvmir", d / "device.mlir", "-o", d / "k.ll"])
    # opt -O3 with the NVPTX target: address-space inference (global loads),
    # LICM/scalar promotion of the accumulator, unrolling.
    run(["opt", "-O3", f"-mcpu={SM}", "-S", d / "k.ll", "-o", d / "k.opt.ll"])
    # -fp-contract=fast lets the backend fuse fmul+fadd into FFMA, the CUDA
    # (nvcc) default; the rounding effect is measured in docs/numerics.md.
    run(["llc", "-O3", "-march=nvptx64", f"-mcpu={SM}", "-fp-contract=fast",
         d / "k.opt.ll", "-o", d / "k.ptx"])
    r = subprocess.run(["ptxas", "-O3", f"-arch={SM}", "-v", str(d / "k.ptx"), "-o", str(d / "k.cubin")],
                       capture_output=True, text=True)
    (d / "ptxas.txt").write_text(r.stdout + r.stderr)
    if r.returncode != 0:
        raise RuntimeError("ptxas failed:\n" + r.stderr)
    (d / "k.sass").write_text(run(["cuobjdump", "-sass", d / "k.cubin"]))
    launch = parse_launch(d / "device.mlir")
    launch["padded"] = [pm, pn, pk]
    (d / "launch.json").write_text(json.dumps(launch))
    return d, launch


def _bench_cmd(workload, m, n, k, kdir=None, launch=None, mode="kernel"):
    cmd = [GPU_BENCH, "--mode", mode, "--workload", workload, "--m", m, "--n", n, "--k", k or 1]
    if mode == "kernel":
        cmd += ["--cubin", kdir / "k.cubin", "--kernel", launch["kernel"],
                "--grid", ",".join(map(str, launch["grid"])),
                "--block", ",".join(map(str, launch["block"])),
                "--args", ",".join(launch["args"])]
        if workload in ("matmul", "mbr"):
            pm, pn, pk = launch.get("padded", [m, n, k])
            cmd += ["--pm", pm, "--pn", pn, "--pk", pk]
    return cmd


def info(workload, m, n, k, kdir, launch):
    """Registers, shared memory, and occupancy from the CUDA occupancy API."""
    return json.loads(run(_bench_cmd(workload, m, n, k, kdir, launch) + ["--info-only"]))


def check(workload, m, n, k, kdir=None, launch=None, mode="kernel", seed=1234):
    """Same FP64 bound as the CPU check (tforge_cpu.check); also returns the output.
    Elementwise workloads (bias_add, relu) must match NumPy float32 exactly."""
    ins = tc.make_inputs(workload, m, n, k, seed)
    if workload in ("bias_add", "relu"):
        with tempfile.TemporaryDirectory() as td:
            for name, arr in ins.items():
                arr.tofile(f"{td}/{name}.bin")
            run(_bench_cmd(workload, m, n, k, kdir, launch, mode) +
                ["--warmup", 0, "--reps", 1, "--in-dir", td, "--out", f"{td}/out.bin"])
            out = np.fromfile(f"{td}/out.bin", dtype=np.float32).reshape(m, n)
        ref = ins["a"] + ins["bias"] if workload == "bias_add" else np.maximum(ins["a"], np.float32(0))
        exact = bool(np.array_equal(out, ref))
        return {"pass": exact, "nan_count": int(np.isnan(out).sum()), "err_over_bound": 0.0 if exact else float("inf"),
                "max_abs_err": float(np.max(np.abs(out.astype(np.float64) - ref)))}, out
    with tempfile.TemporaryDirectory() as td:
        for name, arr in ins.items():
            arr.tofile(f"{td}/{name}.bin")
        out_path = f"{td}/out.bin"
        run(_bench_cmd(workload, m, n, k, kdir, launch, mode) +
            ["--warmup", 0, "--reps", 1, "--in-dir", td, "--out", out_path])
        out = np.fromfile(out_path, dtype=np.float32).reshape(m, n)
    a64, b64 = ins["a"].astype(np.float64), ins["b"].astype(np.float64)
    ref, mag, steps = a64 @ b64, np.abs(a64) @ np.abs(b64), k
    if workload == "mbr":
        bias64 = ins["bias"].astype(np.float64)
        ref, mag, steps = np.maximum(ref + bias64, 0.0), mag + np.abs(bias64), k + 1
    gamma = steps * tc.F32_EPS / (1 - steps * tc.F32_EPS)
    err = np.abs(out.astype(np.float64) - ref)
    res = {"nan_count": int(np.isnan(out).sum()),
           "max_abs_err": float(np.nanmax(err)) if err.size else 0.0,
           "err_over_bound": float(np.nanmax(err / (gamma * mag + np.finfo(np.float32).tiny)))}
    res["pass"] = res["nan_count"] == 0 and res["err_over_bound"] <= 1.0
    return res, out


def bench(workload, m, n, k, kdir=None, launch=None, mode="kernel", warmup=10, reps=100, flush=False):
    cmd = _bench_cmd(workload, m, n, k, kdir, launch, mode) + ["--warmup", warmup, "--reps", reps]
    if flush:
        cmd.append("--flush")
    return json.loads(run(cmd))


def ptxas_resources(kdir):
    """Registers, spill stores/loads, and shared memory from ptxas -v."""
    t = (pathlib.Path(kdir) / "ptxas.txt").read_text()
    g = lambda pat: int(m.group(1)) if (m := re.search(pat, t)) else 0
    return {"regs": g(r"Used (\d+) registers"), "spill_stores": g(r"(\d+) bytes spill stores"),
            "spill_loads": g(r"(\d+) bytes spill loads"), "smem": g(r"(\d+) bytes smem")}
