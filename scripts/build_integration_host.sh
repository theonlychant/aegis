#!/usr/bin/env bash
set -euo pipefail
ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
# Build Rust ffi for host (linux x86_64 assumed)
TARGET="x86_64-unknown-linux-gnu"
cargo build --manifest-path "$ROOT_DIR/engine-rust/ffi/Cargo.toml" --release --target "$TARGET"
LIB_DIR_TARGET="$ROOT_DIR/engine-rust/ffi/target/$TARGET/release"
LIB_DIR_DEFAULT="$ROOT_DIR/engine-rust/ffi/target/release"
echo "Checking for built static libraries in:"
echo " - $LIB_DIR_TARGET"
echo " - $LIB_DIR_DEFAULT"
ls -la "$LIB_DIR_TARGET" 2>/dev/null || true
ls -la "$LIB_DIR_DEFAULT" 2>/dev/null || true
# Find any produced static library (check both per-target and default release dirs)
LIB_PATH="$(ls "$LIB_DIR_TARGET"/lib*.a 2>/dev/null || true)"
if [[ -z "$LIB_PATH" ]]; then
  LIB_PATH="$(ls "$LIB_DIR_DEFAULT"/lib*.a 2>/dev/null | head -n1 || true)"
fi
if [[ -z "$LIB_PATH" || ! -f "$LIB_PATH" ]]; then
  echo "Rust static lib not found in either $LIB_DIR_TARGET or $LIB_DIR_DEFAULT"
  exit 1
fi
echo "Using Rust static lib: $LIB_PATH"

# Build engine-cpp with CMake linking the rust static lib
BUILD_DIR="$ROOT_DIR/build/engine-cpp-host"
mkdir -p "$BUILD_DIR"
pushd "$BUILD_DIR"
cmake -DCMAKE_BUILD_TYPE=Release -DRUST_FFI_LIB="$LIB_PATH" "$ROOT_DIR/engine-cpp"
cmake --build . -- -j$(nproc)
# Run the demo
./engine_cpp_run || true
popd

echo "Host integration build+run complete"
