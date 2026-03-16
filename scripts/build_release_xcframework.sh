#!/usr/bin/env bash
# Build a hardened XCFramework for the Rust FFI lib.
# This script is a starting point — adjust targets and crate name as needed.
set -euo pipefail
ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
CRATE_NAME="ffi"
IOS_DEVICE_TARGET="aarch64-apple-ios"
IOS_SIM_TARGET="x86_64-apple-ios"
# Build device
cargo build --manifest-path "$ROOT_DIR/engine-rust/ffi/Cargo.toml" --release --target $IOS_DEVICE_TARGET
# Build simulator
cargo build --manifest-path "$ROOT_DIR/engine-rust/ffi/Cargo.toml" --release --target $IOS_SIM_TARGET

# Paths to static libs (adjust crate artifact path if different)
DEVICE_LIB="$ROOT_DIR/engine-rust/ffi/target/$IOS_DEVICE_TARGET/release/lib${CRATE_NAME}.a"
SIM_LIB="$ROOT_DIR/engine-rust/ffi/target/$IOS_SIM_TARGET/release/lib${CRATE_NAME}.a"

# Fallback: Cargo may emit into deps/ or name artifacts with hashes. Find matching .a if exact path missing.
if [ ! -f "$DEVICE_LIB" ]; then
  for f in "$ROOT_DIR/engine-rust/ffi/target/$IOS_DEVICE_TARGET/release"/lib${CRATE_NAME}-*.a "$ROOT_DIR/engine-rust/ffi/target/$IOS_DEVICE_TARGET/release"/*.a; do
    if [ -f "$f" ]; then
      DEVICE_LIB="$f"
      break
    fi
  done
fi
if [ ! -f "$SIM_LIB" ]; then
  for f in "$ROOT_DIR/engine-rust/ffi/target/$IOS_SIM_TARGET/release"/lib${CRATE_NAME}-*.a "$ROOT_DIR/engine-rust/ffi/target/$IOS_SIM_TARGET/release"/*.a; do
    if [ -f "$f" ]; then
      SIM_LIB="$f"
      break
    fi
  done
fi
INCLUDE_DIR="$ROOT_DIR/engine-c/include"
OUT_DIR="$ROOT_DIR/build/xcframework"
mkdir -p "$OUT_DIR"

# Optionally strip symbols (requires Xcode tools)
if command -v xcrun >/dev/null 2>&1; then
  echo "Stripping symbols from device lib"
  xcrun strip -S "$DEVICE_LIB" || true
  echo "Stripping symbols from simulator lib"
  xcrun strip -S "$SIM_LIB" || true
fi

# Create XCFramework
xcodebuild -create-xcframework \
  -library "$DEVICE_LIB" -headers "$INCLUDE_DIR" \
  -library "$SIM_LIB" -headers "$INCLUDE_DIR" \
  -output "$OUT_DIR/AegisFFI.xcframework"

echo "XCFramework created at $OUT_DIR/AegisFFI.xcframework"
