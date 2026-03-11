#!/usr/bin/env bash
set -euo pipefail

# Build Rust FFI for iOS targets and produce static libraries.
# Intended to run on macOS with Xcode toolchain installed.

TARGETS=(aarch64-apple-ios x86_64-apple-ios)
BUILD_DIR="target_ios"
RELEASE_DIR="$BUILD_DIR/release"

mkdir -p "$RELEASE_DIR"

echo "Adding Rust targets..."
for t in "${TARGETS[@]}"; do
  rustup target add "$t" || true
done

# Build for each target
for t in "${TARGETS[@]}"; do
  echo "Building for $t"
  # Build the FFI crate directly so artifacts land under engine-rust/ffi/target
  cargo build --manifest-path engine-rust/ffi/Cargo.toml --release --target "$t"
  LIB_PATH="engine-rust/ffi/target/$t/release"
  # Copy produced library artifacts (.a or .dylib) into release dir
  if [ -f "$LIB_PATH/libffi.a" ]; then
    cp "$LIB_PATH/libffi.a" "$RELEASE_DIR/libffi-$t.a"
  elif [ -f "$LIB_PATH/libffi.dylib" ]; then
    cp "$LIB_PATH/libffi.dylib" "$RELEASE_DIR/libffi-$t.dylib"
  else
    echo "Warning: no libffi.* for $t in $LIB_PATH"
  fi
done

echo "Artifacts in $RELEASE_DIR"

echo "You can now use scripts/create_xcframework.sh to build an XCFramework from the built libraries."
