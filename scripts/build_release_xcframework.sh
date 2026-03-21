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

 # Candidate directories to search for produced .a artifacts
CANDIDATE_DIRS=(
  "$ROOT_DIR/engine-rust/ffi/target/$IOS_DEVICE_TARGET/release"
  "$ROOT_DIR/engine-rust/ffi/target/$IOS_SIM_TARGET/release"
  "$ROOT_DIR/engine-rust/ffi/target/release"
  "$ROOT_DIR/engine-rust/target/$IOS_DEVICE_TARGET/release"
  "$ROOT_DIR/engine-rust/target/$IOS_SIM_TARGET/release"
  "$ROOT_DIR/engine-rust/target/release"
)

# Helper: find a library for a given triple (tries exact name then wildcard)
find_lib_for_target() {
  local triple_dir="$1"
  local name="$2"
  # Exact path first
  if [ -f "$triple_dir/lib${name}.a" ]; then
    echo "$triple_dir/lib${name}.a"
    return 0
  fi
  # Wildcard matches (libname-*.a) then any .a
  shopt -s nullglob 2>/dev/null || true
  for f in "$triple_dir/lib${name}-"*.a "$triple_dir"/*.a; do
    if [ -f "$f" ]; then
      echo "$f"
      return 0
    fi
  done
  return 1
}

# Search for device and simulator libs across candidate dirs
DEVICE_LIB=""
SIM_LIB=""
for d in "${CANDIDATE_DIRS[@]}"; do
  # check device dir candidate
  if [ -z "$DEVICE_LIB" ]; then
    DEVICE_LIB_CANDIDATE=$(find_lib_for_target "$d" "$CRATE_NAME" 2>/dev/null || true)
    if [ -n "$DEVICE_LIB_CANDIDATE" ]; then
      DEVICE_LIB="$DEVICE_LIB_CANDIDATE"
    fi
  fi
  # check simulator dir candidate
  if [ -z "$SIM_LIB" ]; then
    SIM_LIB_CANDIDATE=$(find_lib_for_target "$d" "$CRATE_NAME" 2>/dev/null || true)
    if [ -n "$SIM_LIB_CANDIDATE" ]; then
      SIM_LIB="$SIM_LIB_CANDIDATE"
    fi
  fi
done

echo "Resolved device lib: ${DEVICE_LIB:-<not found>}"
echo "Resolved simulator lib: ${SIM_LIB:-<not found>}"

if [ ! -f "$DEVICE_LIB" ]; then
  echo "error: the path does not point to a valid library: $DEVICE_LIB"
  exit 70
fi
if [ ! -f "$SIM_LIB" ]; then
  echo "error: the path does not point to a valid library: $SIM_LIB"
  exit 71
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
