#!/usr/bin/env bash
set -euo pipefail
ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
# Build Rust ffi for host (linux x86_64 assumed)
TARGET="x86_64-unknown-linux-gnu"
cargo build --manifest-path "$ROOT_DIR/engine-rust/ffi/Cargo.toml" --release --target "$TARGET"
LIB_DIRS=(
  "$ROOT_DIR/engine-rust/ffi/target/$TARGET/release"
  "$ROOT_DIR/engine-rust/ffi/target/release"
  "$ROOT_DIR/engine-rust/target/$TARGET/release"
  "$ROOT_DIR/engine-rust/target/release"
)
echo "Checking for built static libraries in:"
for d in "${LIB_DIRS[@]}"; do
  echo " - $d"
  ls -la "$d" 2>/dev/null || true
done
# Find any produced static library across possible release dirs
LIB_PATH=""
for d in "${LIB_DIRS[@]}"; do
  candidate=$(ls "$d"/lib*.a 2>/dev/null | head -n1 || true)
  if [[ -n "$candidate" ]]; then
    LIB_PATH="$candidate"
    break
  fi
done
if [[ -z "$LIB_PATH" || ! -f "$LIB_PATH" ]]; then
  echo "Rust static lib not found in any of the expected release directories"
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
