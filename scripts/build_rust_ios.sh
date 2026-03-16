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
  # Build the FFI crate directly and force the target dir so artifacts
  # land under engine-rust/ffi/target/<target>/release as expected.
  cargo build --manifest-path engine-rust/ffi/Cargo.toml --release --target "$t" --target-dir engine-rust/ffi/target
  LIB_PATH="engine-rust/ffi/target/$t/release"
  # Copy produced library artifacts (.a or .dylib) into release dir
  # Prefer top-level libffi artifacts
  if [ -f "$LIB_PATH/libffi.a" ]; then
    cp "$LIB_PATH/libffi.a" "$RELEASE_DIR/libffi-$t.a"
  elif [ -f "$LIB_PATH/libffi.dylib" ]; then
    cp "$LIB_PATH/libffi.dylib" "$RELEASE_DIR/libffi-$t.dylib"
  else
    # Search deps/ for a matching static archive (Cargo may emit into deps/)
    DEPS_DIR="$LIB_PATH/deps"
    found=0
    if [ -d "$DEPS_DIR" ]; then
      for f in "$DEPS_DIR"/libffi-*.a "$DEPS_DIR"/libffi-*.dylib "$DEPS_DIR"/*.a; do
        if [ -f "$f" ]; then
          base=$(basename "$f")
          cp "$f" "$RELEASE_DIR/${base%.*}-$t.${base##*.}"
          found=1
          break
        fi
      done
    fi
    if [ "$found" -eq 0 ]; then
      echo "Warning: no libffi.* for $t in $LIB_PATH or $DEPS_DIR"
      echo "Contents of $LIB_PATH:" && ls -la "$LIB_PATH" || true
      echo "Contents of $DEPS_DIR:" && ls -la "$DEPS_DIR" || true
    fi
  fi
done

echo "Artifacts in $RELEASE_DIR"

echo "You can now use scripts/create_xcframework.sh to build an XCFramework from the built libraries."
