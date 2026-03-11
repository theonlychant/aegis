#!/usr/bin/env bash
set -euo pipefail
ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
# Build Rust ffi for host (linux x86_64 assumed)
TARGET="x86_64-unknown-linux-gnu"
cargo build --manifest-path "$ROOT_DIR/engine-rust/ffi/Cargo.toml" --release --target "$TARGET"
LIB_PATH="$ROOT_DIR/engine-rust/ffi/target/$TARGET/release/libaegis_ffi.a"
if [[ ! -f "$LIB_PATH" ]]; then
  echo "Rust static lib not found at $LIB_PATH"
  exit 1
fi

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
