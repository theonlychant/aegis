Performance hardening and benchmarking

Quick start

- Rust benchmark (local):
  - Create a Rust binary or run the provided `perf/rust_bench.rs` via `rustc perf/rust_bench.rs -o perf_rust && ./perf_rust` or integrate into Cargo.

- C++ benchmark (local):
  - Build and run `perf/cpp_bench.cpp`:

```bash
mkdir -p perf/build
cd perf/build
cmake ..
cmake --build . --target all
./cpp_bench
```

Profiling

- On macOS use Instruments or `sudo dtruss` / `sample`.
- On Linux use `perf` and `gprof`.

Optimize paths

- Focus on common-case rule matching: Aho-Corasick already gives linear multi-pattern matching.
- If CPU-bound, consider compiling rule automata to a compact bytecode and using SIMD-accelerated matching for binary blobs.
- Profile with realistic corpora to identify hotspots.

Battery-aware scheduling

- Use `BGProcessingTask` for heavy scans and skip work when `ProcessInfo.processInfo.isLowPowerModeEnabled` or battery low.
- Respect user settings and provide throttling in UI.
