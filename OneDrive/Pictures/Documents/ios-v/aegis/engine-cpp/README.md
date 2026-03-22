engine-cpp — High-performance heuristics (C++)

This folder now builds together with `engine-c` so the C bridge is available to C++ code.

Build (out-of-source):

```bash
mkdir -p build && cd build
cmake ..
cmake --build .
./engine_cpp_run
```

The example `main.cpp` calls `aegis_hello()` from the C bridge to demonstrate linking.

Integration with Rust FFI:
- When you build the Rust `ffi` cdylib/static libs, add them to the link step in CMake and expose headers in `engine-c/include`.
- Prefer building an XCFramework for iOS and linking via Xcode for the iOS app.
