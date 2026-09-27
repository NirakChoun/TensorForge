// tforge-gpu-bench: load a TensorForge cubin with the CUDA driver API, launch
// it, check it, and time it. Timing follows KernelForge's harness: CUDA events
// around each rep, warm-up reps not recorded, optional L2 flush (a 256 MiB
// write) before each rep outside the timed region. After every rep the SM
// clock and board power are sampled through NVML so results can be reported
// clock-adjusted.
//
//   tforge-gpu-bench --mode kernel --cubin k.cubin --kernel entry_kernel
//       --grid 2,5,1 --block 16,16,1 --args arg2,arg0,arg1,arg3,f32bits:0
//       --workload mbr --m M --n N --k K [--warmup 10 --reps 100 --flush]
//       [--in-dir d --out o.bin]
//   tforge-gpu-bench --mode cublas --workload mbr --m M --n N --k K ...
//
// --pm/--pn/--pk give the padded problem a staged (Stage 8) kernel was
// compiled for. The runner then keeps zero-initialized padded buffers and, in
// every timed call, copies A, B, and bias into them, launches the kernel, and
// copies the valid M x N block of C out (cudaMemcpy2DAsync, same stream), so
// padding cost is part of the measured time.
//
// Buffers are indexed as the host entry function's arguments:
//   matmul: arg0=A (MxK) arg1=B (KxN) arg2=C (MxN)
//   mbr:    arg0=A arg1=B arg2=bias (N) arg3=C
// Output: one JSON object on stdout.

#include <cublas_v2.h>
#include <cuda.h>
#include <cuda_runtime.h>
#include <nvml.h>

#include <algorithm>
#include <cmath>
#include <cstdint>
#include <cstdio>
#include <cstdlib>
#include <cstring>
#include <fstream>
#include <functional>
#include <iterator>
#include <random>
#include <sstream>
#include <string>
#include <vector>

#define CU(x) check_cu((x), #x, __LINE__)
#define CUDA(x) check_cuda((x), #x, __LINE__)
#define CUBLAS(x) check_cublas((x), #x, __LINE__)

static void die(const std::string &m) {
  std::fprintf(stderr, "tforge-gpu-bench: %s\n", m.c_str());
  std::exit(1);
}
static void check_cu(CUresult r, const char *what, int line) {
  if (r != CUDA_SUCCESS) {
    const char *s = nullptr;
    cuGetErrorString(r, &s);
    die(std::string(what) + " failed (line " + std::to_string(line) + "): " + (s ? s : "?"));
  }
}
static void check_cuda(cudaError_t r, const char *what, int line) {
  if (r != cudaSuccess)
    die(std::string(what) + " failed (line " + std::to_string(line) + "): " + cudaGetErrorString(r));
}
static void check_cublas(cublasStatus_t r, const char *what, int line) {
  if (r != CUBLAS_STATUS_SUCCESS)
    die(std::string(what) + " failed (line " + std::to_string(line) + "): status " + std::to_string(r));
}

struct Args {
  std::string mode = "kernel", cubin, kernel, workload, inDir, out;
  std::vector<int> grid{1, 1, 1}, block{1, 1, 1};
  std::vector<std::string> kargs;
  long m = 0, n = 0, k = 0, pm = 0, pn = 0, pk = 0;
  int warmup = 10, reps = 100;
  bool flush = false;
  unsigned seed = 1234;
};

static std::vector<std::string> split(const std::string &s) {
  std::vector<std::string> out;
  std::stringstream ss(s);
  std::string item;
  while (std::getline(ss, item, ','))
    if (!item.empty()) out.push_back(item);
  return out;
}

static Args parse(int argc, char **argv) {
  Args a;
  for (int i = 1; i < argc; ++i) {
    std::string f = argv[i];
    auto next = [&]() -> std::string {
      if (i + 1 >= argc) die("missing value for " + f);
      return argv[++i];
    };
    auto dims = [&](std::vector<int> &d) {
      auto v = split(next());
      if (v.size() != 3) die(f + " needs x,y,z");
      for (int j = 0; j < 3; ++j) d[j] = std::stoi(v[j]);
    };
    if (f == "--mode") a.mode = next();
    else if (f == "--cubin") a.cubin = next();
    else if (f == "--kernel") a.kernel = next();
    else if (f == "--grid") dims(a.grid);
    else if (f == "--block") dims(a.block);
    else if (f == "--args") a.kargs = split(next());
    else if (f == "--workload") a.workload = next();
    else if (f == "--m") a.m = std::stol(next());
    else if (f == "--n") a.n = std::stol(next());
    else if (f == "--k") a.k = std::stol(next());
    else if (f == "--pm") a.pm = std::stol(next());
    else if (f == "--pn") a.pn = std::stol(next());
    else if (f == "--pk") a.pk = std::stol(next());
    else if (f == "--warmup") a.warmup = std::stoi(next());
    else if (f == "--reps") a.reps = std::stoi(next());
    else if (f == "--flush") a.flush = true;
    else if (f == "--in-dir") a.inDir = next();
    else if (f == "--out") a.out = next();
    else if (f == "--seed") a.seed = std::stoul(next());
    else die("unknown flag " + f);
  }
  if (a.workload != "matmul" && a.workload != "mbr") die("--workload matmul|mbr");
  if (a.m <= 0 || a.n <= 0 || a.k <= 0) die("need --m --n --k");
  if (!a.pm) a.pm = a.m;
  if (!a.pn) a.pn = a.n;
  if (!a.pk) a.pk = a.k;
  if (a.pm < a.m || a.pn < a.n || a.pk < a.k) die("padded sizes must be >= M, N, K");
  if (a.mode == "kernel" && (a.cubin.empty() || a.kernel.empty() || a.kargs.empty()))
    die("kernel mode needs --cubin --kernel --args");
  return a;
}

// relu(C + bias) as a separate kernel: the unfused epilogue after cuBLAS.
__global__ void bias_relu(float *c, const float *bias, long m, long n) {
  long i = blockIdx.x * (long)blockDim.x + threadIdx.x;
  if (i < m * n) c[i] = fmaxf(c[i] + bias[i % n], 0.0f);
}

struct Stats {
  double median, min, mean, sd;
};
static Stats stats(std::vector<double> v) {
  std::sort(v.begin(), v.end());
  size_t n = v.size();
  double mean = 0;
  for (double x : v) mean += x;
  mean /= n;
  double var = 0;
  for (double x : v) var += (x - mean) * (x - mean);
  double med = n % 2 ? v[n / 2] : 0.5 * (v[n / 2 - 1] + v[n / 2]);
  return {med, v.front(), mean, n > 1 ? std::sqrt(var / (n - 1)) : 0.0};
}

static void fill(std::vector<float> &v, const Args &a, const char *name, std::mt19937 &rng) {
  if (!a.inDir.empty()) {
    std::ifstream f(a.inDir + "/" + name + ".bin", std::ios::binary);
    if (!f) die(std::string("cannot read ") + name);
    f.read(reinterpret_cast<char *>(v.data()), v.size() * sizeof(float));
    if ((size_t)f.gcount() != v.size() * sizeof(float)) die(std::string("short read ") + name);
    return;
  }
  std::uniform_real_distribution<float> d(-1.0f, 1.0f);
  for (float &x : v) x = d(rng);
}

int main(int argc, char **argv) {
  Args a = parse(argc, argv);
  const long M = a.m, N = a.n, K = a.k;
  const bool mbr = a.workload == "mbr";

  CUDA(cudaSetDevice(0));
  CUDA(cudaFree(nullptr));  // creates the primary context the driver API also uses
  CU(cuInit(0));
  CUdevice dev;
  CU(cuDeviceGet(&dev, 0));
  char name[256];
  CU(cuDeviceGetName(name, sizeof name, dev));

  // Host data and device buffers, in host-entry-argument order.
  std::mt19937 rng(a.seed);
  std::vector<float> hA(M * K), hB(K * N), hBias(N), hC(M * N);
  fill(hA, a, "a", rng);
  fill(hB, a, "b", rng);
  if (mbr) fill(hBias, a, "bias", rng);
  float *dA, *dB, *dBias = nullptr, *dC;
  CUDA(cudaMalloc(&dA, hA.size() * 4));
  CUDA(cudaMalloc(&dB, hB.size() * 4));
  CUDA(cudaMalloc(&dC, hC.size() * 4));
  if (mbr) CUDA(cudaMalloc(&dBias, N * 4));
  CUDA(cudaMemcpy(dA, hA.data(), hA.size() * 4, cudaMemcpyHostToDevice));
  CUDA(cudaMemcpy(dB, hB.data(), hB.size() * 4, cudaMemcpyHostToDevice));
  if (mbr) CUDA(cudaMemcpy(dBias, hBias.data(), N * 4, cudaMemcpyHostToDevice));
  std::vector<void *> bufs = {dA, dB};
  if (mbr) bufs.push_back(dBias);
  bufs.push_back(dC);
  const long PM = a.pm, PN = a.pn, PK = a.pk;
  const bool padded = a.mode == "kernel" && (PM != M || PN != N || PK != K);
  float *pA = nullptr, *pB = nullptr, *pBias = nullptr, *pC = nullptr;
  if (padded) {
    // Zeroed once: the pad regions are never written by the copies, so they
    // stay zero and contribute nothing to the valid block.
    CUDA(cudaMalloc(&pA, PM * PK * 4));
    CUDA(cudaMalloc(&pB, PK * PN * 4));
    CUDA(cudaMalloc(&pC, PM * PN * 4));
    CUDA(cudaMemset(pA, 0, PM * PK * 4));
    CUDA(cudaMemset(pB, 0, PK * PN * 4));
    if (mbr) {
      CUDA(cudaMalloc(&pBias, PN * 4));
      CUDA(cudaMemset(pBias, 0, PN * 4));
    }
    bufs = {pA, pB};
    if (mbr) bufs.push_back(pBias);
    bufs.push_back(pC);
  }

  cudaStream_t stream;
  CUDA(cudaStreamCreate(&stream));
  cublasHandle_t blas = nullptr;
  std::function<void()> run;

  // Kernel-mode state.
  CUmodule mod = nullptr;
  CUfunction fn = nullptr;
  std::vector<CUdeviceptr> ptrArgs;
  std::vector<float> f32Args;
  std::vector<int64_t> i64Args;
  std::vector<void *> params;
  int regs = -1, localBytes = -1, smem = -1, blocksPerSm = -1;
  double occupancy = -1;

  if (a.mode == "kernel") {
    std::ifstream f(a.cubin, std::ios::binary);
    if (!f) die("cannot read " + a.cubin);
    std::vector<char> image((std::istreambuf_iterator<char>(f)), std::istreambuf_iterator<char>());
    CU(cuModuleLoadData(&mod, image.data()));
    CU(cuModuleGetFunction(&fn, mod, a.kernel.c_str()));
    // Stable storage for kernel parameters: reserve so pointers do not move.
    ptrArgs.reserve(a.kargs.size());
    f32Args.reserve(a.kargs.size());
    i64Args.reserve(a.kargs.size());
    for (const std::string &s : a.kargs) {
      if (s.rfind("arg", 0) == 0) {
        size_t idx = std::stoul(s.substr(3));
        if (idx >= bufs.size()) die("kernel arg refers to missing buffer " + s);
        ptrArgs.push_back(reinterpret_cast<CUdeviceptr>(bufs[idx]));
        params.push_back(&ptrArgs.back());
      } else if (s.rfind("i64:", 0) == 0) {
        i64Args.push_back(std::stoll(s.substr(4)));
        params.push_back(&i64Args.back());
      } else if (s.rfind("f32bits:", 0) == 0) {
        uint32_t bits = static_cast<uint32_t>(std::stoul(s.substr(8)));
        float v;
        std::memcpy(&v, &bits, 4);
        f32Args.push_back(v);
        params.push_back(&f32Args.back());
      } else {
        die("bad kernel arg spec " + s);
      }
    }
    CU(cuFuncGetAttribute(&regs, CU_FUNC_ATTRIBUTE_NUM_REGS, fn));
    CU(cuFuncGetAttribute(&localBytes, CU_FUNC_ATTRIBUTE_LOCAL_SIZE_BYTES, fn));
    CU(cuFuncGetAttribute(&smem, CU_FUNC_ATTRIBUTE_SHARED_SIZE_BYTES, fn));
    int threads = a.block[0] * a.block[1] * a.block[2];
    CU(cuOccupancyMaxActiveBlocksPerMultiprocessor(&blocksPerSm, fn, threads, 0));
    int maxThreadsSm = 0, warp = 32;
    CU(cuDeviceGetAttribute(&maxThreadsSm, CU_DEVICE_ATTRIBUTE_MAX_THREADS_PER_MULTIPROCESSOR, dev));
    occupancy = double(blocksPerSm * ((threads + warp - 1) / warp)) / (maxThreadsSm / warp);
    run = [&] {
      if (padded) {
        CUDA(cudaMemcpy2DAsync(pA, PK * 4, dA, K * 4, K * 4, M, cudaMemcpyDeviceToDevice, stream));
        CUDA(cudaMemcpy2DAsync(pB, PN * 4, dB, N * 4, N * 4, K, cudaMemcpyDeviceToDevice, stream));
        if (mbr) CUDA(cudaMemcpyAsync(pBias, dBias, N * 4, cudaMemcpyDeviceToDevice, stream));
      }
      CU(cuLaunchKernel(fn, a.grid[0], a.grid[1], a.grid[2], a.block[0], a.block[1], a.block[2],
                        0, stream, params.data(), nullptr));
      if (padded)
        CUDA(cudaMemcpy2DAsync(dC, N * 4, pC, PN * 4, N * 4, M, cudaMemcpyDeviceToDevice, stream));
    };
  } else if (a.mode == "cublas") {
    CUBLAS(cublasCreate(&blas));
    CUBLAS(cublasSetStream(blas, stream));
    // Default math mode: FP32 FMA, no TF32 (TF32 needs CUBLAS_TF32_TENSOR_OP_MATH).
    CUBLAS(cublasSetMathMode(blas, CUBLAS_DEFAULT_MATH));
    const float one = 1.0f, zero = 0.0f;
    run = [&, one, zero] {
      // Row-major C = A B computed as column-major C^T = B^T A^T.
      CUBLAS(cublasSgemm(blas, CUBLAS_OP_N, CUBLAS_OP_N, (int)N, (int)M, (int)K, &one, dB, (int)N,
                         dA, (int)K, &zero, dC, (int)N));
      if (mbr) {
        long total = M * N;
        bias_relu<<<(unsigned)((total + 255) / 256), 256, 0, stream>>>(dC, dBias, M, N);
        CUDA(cudaGetLastError());
      }
    };
  } else {
    die("--mode kernel|cublas");
  }

  // Correctness run: output pre-filled with NaN (0xFF bytes).
  CUDA(cudaMemset(dC, 0xFF, hC.size() * 4));
  run();
  CUDA(cudaStreamSynchronize(stream));
  CUDA(cudaMemcpy(hC.data(), dC, hC.size() * 4, cudaMemcpyDeviceToHost));
  if (!a.out.empty()) {
    std::ofstream o(a.out, std::ios::binary);
    o.write(reinterpret_cast<const char *>(hC.data()), hC.size() * 4);
  }

  // NVML for clocks and power.
  nvmlDevice_t nvdev;
  bool haveNvml = nvmlInit_v2() == NVML_SUCCESS && nvmlDeviceGetHandleByIndex_v2(0, &nvdev) == NVML_SUCCESS;

  void *flushBuf = nullptr;
  size_t flushBytes = size_t(256) << 20;
  if (a.flush) CUDA(cudaMalloc(&flushBuf, flushBytes));
  unsigned flushVal = 0;

  cudaEvent_t e0, e1;
  CUDA(cudaEventCreate(&e0));
  CUDA(cudaEventCreate(&e1));
  for (int i = 0; i < a.warmup; ++i) run();
  CUDA(cudaStreamSynchronize(stream));
  std::vector<double> ms(a.reps), clk, pwr;
  for (int i = 0; i < a.reps; ++i) {
    if (a.flush)
      CU(cuMemsetD32Async(reinterpret_cast<CUdeviceptr>(flushBuf), ++flushVal, flushBytes / 4, stream));
    CUDA(cudaEventRecord(e0, stream));
    run();
    CUDA(cudaEventRecord(e1, stream));
    CUDA(cudaEventSynchronize(e1));
    float t;
    CUDA(cudaEventElapsedTime(&t, e0, e1));
    ms[i] = t;
    unsigned c = 0, p = 0;
    if (haveNvml && nvmlDeviceGetClockInfo(nvdev, NVML_CLOCK_SM, &c) == NVML_SUCCESS) clk.push_back(c);
    if (haveNvml && nvmlDeviceGetPowerUsage(nvdev, &p) == NVML_SUCCESS) pwr.push_back(p / 1000.0);
  }
  CUDA(cudaGetLastError());
  Stats s = stats(ms);
  Stats c = clk.empty() ? Stats{-1, -1, -1, -1} : stats(clk);
  double clkMax = clk.empty() ? -1 : *std::max_element(clk.begin(), clk.end());
  Stats p = pwr.empty() ? Stats{-1, -1, -1, -1} : stats(pwr);
  int driver = 0;
  CU(cuDriverGetVersion(&driver));

  std::printf(
      "{\"gpu\": \"%s\", \"mode\": \"%s\", \"workload\": \"%s\", \"m\": %ld, \"n\": %ld, \"k\": %ld, "
      "\"padded\": \"%ldx%ldx%ld\", "
      "\"grid\": \"%dx%dx%d\", \"block\": \"%dx%dx%d\", \"regs\": %d, \"local_bytes\": %d, "
      "\"static_smem\": %d, \"blocks_per_sm\": %d, \"theo_occupancy\": %.3f, "
      "\"warmup\": %d, \"reps\": %d, \"l2_flush\": %d, \"median_ms\": %.6f, \"min_ms\": %.6f, "
      "\"std_ms\": %.6f, \"sm_clock_median_mhz\": %.0f, \"sm_clock_min_mhz\": %.0f, "
      "\"sm_clock_max_mhz\": %.0f, \"power_median_w\": %.1f, \"cuda_driver\": %d}\n",
      name, a.mode.c_str(), a.workload.c_str(), M, N, K, padded ? PM : M, padded ? PN : N,
      padded ? PK : K, a.grid[0], a.grid[1], a.grid[2],
      a.block[0], a.block[1], a.block[2], regs, localBytes, smem, blocksPerSm, occupancy, a.warmup,
      a.reps, a.flush ? 1 : 0, s.median, s.min, s.sd, c.median, c.min, clkMax, p.median, driver);
  return 0;
}
