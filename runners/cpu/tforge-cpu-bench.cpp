//===- tforge-cpu-bench.cpp - run and time a compiled TensorForge kernel --===//
//
// Loads a shared object produced by the CPU pipeline and calls its
// `_mlir_ciface_entry`. The pipeline uses buffer-results-to-out-params, so the
// caller owns the output buffer and the entry signature is (inputs..., out).
//
//   tforge-cpu-bench --lib k.so --workload mbr --m 256 --n 256 --k 256
//                    [--warmup 10 --reps 100] [--in-dir d --out o.bin]
//
// Heap allocations made by the kernel go through the generic allocation hooks
// (finalize-memref-to-llvm{use-generic-functions}) defined below, so the
// harness can report the bytes a kernel allocates per call. This is how Stage 5
// measures materialized intermediates. The executable is linked with
// -rdynamic so the loaded kernel resolves these symbols here.
//
// Output: one JSON object on stdout.
//
//===----------------------------------------------------------------------===//

#include <dlfcn.h>
#include <sched.h>

#include <algorithm>
#include <atomic>
#include <chrono>
#include <cmath>
#include <cstdint>
#include <cstdio>
#include <cstdlib>
#include <cstring>
#include <fstream>
#include <functional>
#include <random>
#include <string>
#include <vector>

namespace {

std::atomic<uint64_t> gAllocBytes{0};
std::atomic<uint64_t> gAllocCount{0};

} // namespace

extern "C" {
void *_mlir_memref_to_llvm_alloc(size_t size) {
  gAllocBytes += size;
  ++gAllocCount;
  return std::malloc(size);
}
void *_mlir_memref_to_llvm_aligned_alloc(size_t alignment, size_t size) {
  gAllocBytes += size;
  ++gAllocCount;
  // aligned_alloc requires size to be a multiple of alignment.
  size_t rounded = (size + alignment - 1) / alignment * alignment;
  return std::aligned_alloc(alignment, rounded);
}
void _mlir_memref_to_llvm_free(void *ptr) { std::free(ptr); }
}

namespace {

/// Heap buffer with 64-byte (cache line) alignment, so every kernel sees the
/// same alignment for inputs and outputs regardless of the C++ allocator.
/// `offsetBytes` shifts the data start (for the alignment experiment only).
class Buffer {
public:
  explicit Buffer(size_t n = 0, size_t offsetBytes = 0) { resize(n, offsetBytes); }
  ~Buffer() { std::free(base_); }
  Buffer(const Buffer &) = delete;
  Buffer &operator=(const Buffer &) = delete;
  void resize(size_t n, size_t offsetBytes = 0) {
    std::free(base_);
    size_t bytes = (n * sizeof(float) + offsetBytes + 63) / 64 * 64 + 64;
    base_ = static_cast<char *>(std::aligned_alloc(64, bytes));
    data_ = reinterpret_cast<float *>(base_ + offsetBytes);
    n_ = n;
  }
  float *data() { return data_; }
  const float *data() const { return data_; }
  size_t size() const { return n_; }
  float *begin() { return data_; }
  float *end() { return data_ + n_; }
  float &operator[](size_t i) { return data_[i]; }

private:
  char *base_ = nullptr;
  float *data_ = nullptr;
  size_t n_ = 0;
};

template <int Rank> struct MemRef {
  float *allocated;
  float *aligned;
  int64_t offset;
  int64_t sizes[Rank];
  int64_t strides[Rank];
};

template <int Rank> MemRef<Rank> view(Buffer &v,
                                      const int64_t (&shape)[Rank]) {
  MemRef<Rank> d{};
  d.allocated = d.aligned = v.data();
  d.offset = 0;
  int64_t stride = 1;
  for (int i = Rank - 1; i >= 0; --i) {
    d.sizes[i] = shape[i];
    d.strides[i] = stride;
    stride *= shape[i];
  }
  return d;
}

struct Args {
  std::string lib, workload, inDir, out;
  int64_t m = 0, n = 0, k = 0;
  int warmup = 10, reps = 100;
  unsigned seed = 1234;
  size_t outOffset = 0;
};

[[noreturn]] void die(const std::string &msg) {
  std::fprintf(stderr, "tforge-cpu-bench: %s\n", msg.c_str());
  std::exit(1);
}

Args parse(int argc, char **argv) {
  Args a;
  for (int i = 1; i < argc; ++i) {
    std::string f = argv[i];
    auto next = [&]() -> std::string {
      if (i + 1 >= argc)
        die("missing value for " + f);
      return argv[++i];
    };
    if (f == "--lib") a.lib = next();
    else if (f == "--workload") a.workload = next();
    else if (f == "--m") a.m = std::stoll(next());
    else if (f == "--n") a.n = std::stoll(next());
    else if (f == "--k") a.k = std::stoll(next());
    else if (f == "--warmup") a.warmup = std::stoi(next());
    else if (f == "--reps") a.reps = std::stoi(next());
    else if (f == "--in-dir") a.inDir = next();
    else if (f == "--out") a.out = next();
    else if (f == "--seed") a.seed = std::stoul(next());
    else if (f == "--out-offset") a.outOffset = std::stoul(next());
    else die("unknown flag " + f);
  }
  if (a.lib.empty() || a.workload.empty() || a.m <= 0 || a.n <= 0)
    die("need --lib, --workload, --m, --n");
  bool needK = a.workload == "matmul" || a.workload == "mbr";
  if (needK && a.k <= 0)
    die("--k required for " + a.workload);
  return a;
}

void fill(Buffer &v, const Args &a, const std::string &name,
          std::mt19937 &rng) {
  if (!a.inDir.empty()) {
    std::ifstream f(a.inDir + "/" + name + ".bin", std::ios::binary);
    if (!f)
      die("cannot read " + a.inDir + "/" + name + ".bin");
    f.read(reinterpret_cast<char *>(v.data()), v.size() * sizeof(float));
    if (static_cast<size_t>(f.gcount()) != v.size() * sizeof(float))
      die("short read for " + name);
    return;
  }
  std::uniform_real_distribution<float> dist(-1.0f, 1.0f);
  for (float &x : v)
    x = dist(rng);
}

/// Pin to the first CPU this process may run on (inside the Slurm cgroup), so
/// the single-threaded kernel does not migrate between cores during timing.
int pinToFirstAllowedCpu() {
  cpu_set_t set;
  if (sched_getaffinity(0, sizeof(set), &set) != 0)
    return -1;
  for (int c = 0; c < CPU_SETSIZE; ++c)
    if (CPU_ISSET(c, &set)) {
      cpu_set_t one;
      CPU_ZERO(&one);
      CPU_SET(c, &one);
      return sched_setaffinity(0, sizeof(one), &one) == 0 ? c : -1;
    }
  return -1;
}

} // namespace

int main(int argc, char **argv) {
  Args a = parse(argc, argv);
  int cpu = pinToFirstAllowedCpu();

  void *handle = dlopen(a.lib.c_str(), RTLD_NOW | RTLD_LOCAL);
  if (!handle)
    die(std::string("dlopen: ") + dlerror());
  void *sym = dlsym(handle, "_mlir_ciface_entry");
  if (!sym)
    die("no _mlir_ciface_entry in " + a.lib);

  std::mt19937 rng(a.seed);
  const int64_t M = a.m, N = a.n, K = a.k;
  Buffer A, B, Bias, Out(M * N, a.outOffset);
  // NaN-fill the output so elements the kernel fails to write are detected.
  for (float &x : Out)
    x = std::nanf("");
  MemRef<2> dA{}, dB{}, dOut = view<2>(Out, {M, N});
  MemRef<1> dBias{};
  std::function<void()> call;

  using Fn2 = void (*)(void *, void *);
  using Fn3 = void (*)(void *, void *, void *);
  using Fn4 = void (*)(void *, void *, void *, void *);
  if (a.workload == "add") {
    A.resize(M * N); B.resize(M * N);
    fill(A, a, "a", rng); fill(B, a, "b", rng);
    dA = view<2>(A, {M, N}); dB = view<2>(B, {M, N});
    auto f = reinterpret_cast<Fn3>(sym);
    call = [&, f] { f(&dA, &dB, &dOut); };
  } else if (a.workload == "relu") {
    A.resize(M * N);
    fill(A, a, "a", rng);
    dA = view<2>(A, {M, N});
    auto f = reinterpret_cast<Fn2>(sym);
    call = [&, f] { f(&dA, &dOut); };
  } else if (a.workload == "matmul" || a.workload == "mbr") {
    A.resize(M * K); B.resize(K * N);
    fill(A, a, "a", rng); fill(B, a, "b", rng);
    dA = view<2>(A, {M, K}); dB = view<2>(B, {K, N});
    if (a.workload == "matmul") {
      auto f = reinterpret_cast<Fn3>(sym);
      call = [&, f] { f(&dA, &dB, &dOut); };
    } else {
      Bias.resize(N);
      fill(Bias, a, "bias", rng);
      dBias = view<1>(Bias, {N});
      auto f = reinterpret_cast<Fn4>(sym);
      call = [&, f] { f(&dA, &dB, &dBias, &dOut); };
    }
  } else {
    die("unknown workload " + a.workload);
  }

  // First call: correctness output and per-call allocation count.
  gAllocBytes = 0;
  gAllocCount = 0;
  call();
  uint64_t allocBytes = gAllocBytes, allocCount = gAllocCount;
  if (!a.out.empty()) {
    std::ofstream f(a.out, std::ios::binary);
    f.write(reinterpret_cast<const char *>(Out.data()),
            Out.size() * sizeof(float));
  }

  for (int i = 0; i < a.warmup; ++i)
    call();
  std::vector<double> ns(a.reps);
  for (int i = 0; i < a.reps; ++i) {
    auto t0 = std::chrono::steady_clock::now();
    call();
    auto t1 = std::chrono::steady_clock::now();
    ns[i] = std::chrono::duration<double, std::nano>(t1 - t0).count();
  }

  double mean = 0;
  for (double x : ns)
    mean += x;
  mean /= ns.size();
  double var = 0;
  for (double x : ns)
    var += (x - mean) * (x - mean);
  double sd = ns.size() > 1 ? std::sqrt(var / (ns.size() - 1)) : 0.0;
  std::vector<double> sorted(ns);
  std::sort(sorted.begin(), sorted.end());
  size_t r = sorted.size();
  double median = r % 2 ? sorted[r / 2] : 0.5 * (sorted[r / 2 - 1] + sorted[r / 2]);
  double checksum = 0;
  for (float x : Out)
    checksum += x;

  std::printf("{\"workload\": \"%s\", \"m\": %lld, \"n\": %lld, \"k\": %lld, "
              "\"warmup\": %d, \"reps\": %d, \"median_ns\": %.1f, "
              "\"min_ns\": %.1f, \"mean_ns\": %.1f, \"std_ns\": %.1f, "
              "\"alloc_bytes_per_call\": %llu, \"alloc_count_per_call\": %llu, "
              "\"threads\": 1, \"cpu\": %d, \"out_offset\": %zu, \"checksum\": %.9g}\n",
              a.workload.c_str(), (long long)M, (long long)N, (long long)K,
              a.warmup, a.reps, median, sorted.front(), mean, sd,
              (unsigned long long)allocBytes, (unsigned long long)allocCount,
              cpu, a.outOffset, checksum);
  return 0;
}
