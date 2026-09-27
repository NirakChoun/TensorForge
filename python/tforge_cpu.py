"""Generate, compile, check, and time TensorForge CPU kernels.

Workloads and their entry signatures (tensors, row-major f32):
  add     entry(a: MxN, b: MxN) -> MxN
  relu    entry(a: MxN) -> MxN
  matmul  entry(a: MxK, b: KxN) -> MxN
  mbr     entry(a: MxK, b: KxN, bias: N) -> MxN      relu(a @ b + bias)
  bias_add entry(a: MxN, bias: N) -> MxN              (GPU ablation baseline only)
"""

import json
import os
import pathlib
import shlex
import subprocess
import tempfile

import numpy as np

ROOT = pathlib.Path(__file__).resolve().parent.parent
BUILD = ROOT / "build"
OPT = BUILD / "bin" / "tensorforge-opt"
BENCH = BUILD / "bin" / "tforge-cpu-bench"
ART = BUILD / "artifacts"

F32_EPS = 2.0 ** -24  # unit roundoff for f32, round to nearest


def gen_mlir(workload, m, n, k=None):
    t = lambda *d: "tensor<" + "x".join(str(x) for x in d) + "xf32>"
    if workload == "add":
        return (f"func.func @entry(%a: {t(m, n)}, %b: {t(m, n)}) -> {t(m, n)} {{\n"
                f"  %0 = tforge.add %a, %b : {t(m, n)}, {t(m, n)} -> {t(m, n)}\n"
                f"  return %0 : {t(m, n)}\n}}\n")
    if workload == "bias_add":
        return (f"func.func @entry(%a: {t(m, n)}, %bias: {t(n)}) -> {t(m, n)} {{\n"
                f"  %0 = tforge.bias_add %a, %bias : {t(m, n)}, {t(n)} -> {t(m, n)}\n"
                f"  return %0 : {t(m, n)}\n}}\n")
    if workload == "relu":
        return (f"func.func @entry(%a: {t(m, n)}) -> {t(m, n)} {{\n"
                f"  %0 = tforge.relu %a : {t(m, n)} -> {t(m, n)}\n"
                f"  return %0 : {t(m, n)}\n}}\n")
    if workload == "matmul":
        return (f"func.func @entry(%a: {t(m, k)}, %b: {t(k, n)}) -> {t(m, n)} {{\n"
                f"  %0 = tforge.matmul %a, %b : {t(m, k)}, {t(k, n)} -> {t(m, n)}\n"
                f"  return %0 : {t(m, n)}\n}}\n")
    if workload == "mbr":
        return (f"func.func @entry(%a: {t(m, k)}, %b: {t(k, n)}, %bias: {t(n)}) -> {t(m, n)} {{\n"
                f"  %0 = tforge.matmul %a, %b : {t(m, k)}, {t(k, n)} -> {t(m, n)}\n"
                f"  %1 = tforge.bias_add %0, %bias : {t(m, n)}, {t(n)} -> {t(m, n)}\n"
                f"  %2 = tforge.relu %1 : {t(m, n)} -> {t(m, n)}\n"
                f"  return %2 : {t(m, n)}\n}}\n")
    raise ValueError(workload)


def run(cmd, **kw):
    cmd = [str(c) for c in cmd]
    kw.setdefault("timeout", 600)  # a hung compile or kernel fails the step
    r = subprocess.run(cmd, capture_output=True, text=True, **kw)
    if r.returncode != 0:
        raise RuntimeError(f"command failed ({r.returncode}): {shlex.join(cmd)}\n{r.stderr}")
    return r.stdout


def pipeline_flag(options=""):
    return f"--tforge-cpu-pipeline={options}" if options else "--tforge-cpu-pipeline"


def compile_kernel(workload, m, n, k=None, options="", tag="default"):
    """tforge MLIR -> LLVM dialect -> LLVM IR -> opt -O3 -> llc -O3 (host CPU) -> .so.

    Returns the directory with every intermediate (input.mlir, llvm.mlir, k.ll,
    k.opt.ll, k.s, k.so) so generated code can be inspected.
    """
    shape = f"{m}x{n}" + (f"x{k}" if k else "")
    d = ART / "cpu" / tag / f"{workload}_{shape}"
    d.mkdir(parents=True, exist_ok=True)
    (d / "input.mlir").write_text(gen_mlir(workload, m, n, k))
    run([OPT, d / "input.mlir", pipeline_flag(options), "-o", d / "llvm.mlir"])
    run(["mlir-translate", "--mlir-to-llvmir", d / "llvm.mlir", "-o", d / "k.ll"])
    run(["opt", "-O3", "-S", d / "k.ll", "-o", d / "k.opt.ll"])
    llc = ["llc", "-O3", "-mcpu=native", "-relocation-model=pic"]
    run(llc + ["-filetype=obj", d / "k.opt.ll", "-o", d / "k.o"])
    run(llc + ["-filetype=asm", d / "k.opt.ll", "-o", d / "k.s"])
    run([os.environ.get("CXX", "c++"), "-shared", d / "k.o", "-o", d / "k.so"])
    return d


def make_inputs(workload, m, n, k, seed=1234):
    rng = np.random.default_rng(seed)
    u = lambda *s: rng.uniform(-1.0, 1.0, size=s).astype(np.float32)
    if workload == "add":
        return {"a": u(m, n), "b": u(m, n)}
    if workload == "relu":
        return {"a": u(m, n)}
    if workload == "bias_add":
        return {"a": u(m, n), "bias": u(n)}
    if workload == "matmul":
        return {"a": u(m, k), "b": u(k, n)}
    return {"a": u(m, k), "b": u(k, n), "bias": u(n)}


def check(workload, m, n, k, kdir, seed=1234):
    """Run once on NumPy-generated inputs and compare with a reference.

    add, relu: bit-exact against NumPy float32 (one IEEE operation per element).
    matmul, mbr: against a float64 reference, with the deterministic bound
    |C - C64| <= gamma_{K+1} * (|A| |B| + |bias|), gamma_j = j*u / (1 - j*u),
    u = 2^-24, which holds for any summation order (Higham, Thm 3.5). The
    reported `err_over_bound` must be <= 1.
    """
    ins = make_inputs(workload, m, n, k, seed)
    with tempfile.TemporaryDirectory() as td:
        for name, arr in ins.items():
            arr.tofile(f"{td}/{name}.bin")
        out_path = f"{td}/out.bin"
        run([BENCH, "--lib", kdir / "k.so", "--workload", workload, "--m", m, "--n", n,
             "--k", k or 0, "--warmup", 0, "--reps", 1, "--in-dir", td, "--out", out_path])
        out = np.fromfile(out_path, dtype=np.float32).reshape(m, n)
    res = {"nan_count": int(np.isnan(out).sum())}
    if workload in ("add", "relu"):
        ref = ins["a"] + ins["b"] if workload == "add" else np.maximum(ins["a"], np.float32(0))
        res.update(exact=bool(np.array_equal(out, ref)),
                   max_abs_err=float(np.max(np.abs(out.astype(np.float64) - ref))),
                   err_over_bound=0.0 if np.array_equal(out, ref) else float("inf"))
        res["pass"] = res["exact"] and res["nan_count"] == 0
        return res
    a64, b64 = ins["a"].astype(np.float64), ins["b"].astype(np.float64)
    ref = a64 @ b64
    mag = np.abs(a64) @ np.abs(b64)
    steps = k
    if workload == "mbr":
        bias64 = ins["bias"].astype(np.float64)
        ref = np.maximum(ref + bias64, 0.0)
        mag = mag + np.abs(bias64)
        steps = k + 1
    gamma = steps * F32_EPS / (1 - steps * F32_EPS)
    bound = gamma * mag + np.finfo(np.float32).tiny
    err = np.abs(out.astype(np.float64) - ref)
    res.update(max_abs_err=float(err.max()),
               max_rel_err=float((err / np.maximum(np.abs(ref), 1e-30)).max()),
               err_over_bound=float((err / bound).max()),
               tolerance=f"gamma_{steps}*(|A||B|+|bias|)")
    res["pass"] = res["err_over_bound"] <= 1.0 and res["nan_count"] == 0
    return res


def bench(workload, m, n, k, kdir, warmup=10, reps=100):
    out = run([BENCH, "--lib", kdir / "k.so", "--workload", workload, "--m", m, "--n", n,
               "--k", k or 0, "--warmup", warmup, "--reps", reps])
    return json.loads(out)


def flops_or_bytes(workload, m, n, k):
    """(metric name, amount of work) for the derived metric."""
    if workload in ("matmul", "mbr"):
        return "GFLOP/s", 2.0 * m * n * k
    arrays = 3 if workload == "add" else 2
    return "GB/s", arrays * m * n * 4.0
