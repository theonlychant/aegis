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
  # Force Cargo to use the crate-local target dir so artifacts
  # land under engine-rust/ffi/target/<target>/release.
  export CARGO_TARGET_DIR="engine-rust/ffi/target"
  cargo build --manifest-path engine-rust/ffi/Cargo.toml --release --target "$t"

  LIB_PATH="${CARGO_TARGET_DIR}/$t/release"

  # Helper: find any libffi* artifact under expected paths and copy it
  copy_found=0
  # Look for common output filenames first
  for cand in "$LIB_PATH/libffi.a" "$LIB_PATH/libffi.dylib"; do
    if [ -f "$cand" ]; then
      ext="${cand##*.}"
      echo "Found $cand -> copying to $RELEASE_DIR/libffi-$t.$ext"
      cp "$cand" "$RELEASE_DIR/libffi-$t.$ext"
      copy_found=1
      break
    fi
  done

  # Fallback: search deps/ and any hashed filenames Cargo may emit
  if [ "$copy_found" -eq 0 ]; then
    DEPS_DIR="$LIB_PATH/deps"
    if [ -d "$DEPS_DIR" ]; then
      echo "Searching $DEPS_DIR for libffi archives"
      shopt -s nullglob || true
      for f in "$DEPS_DIR"/libffi-*.a "$DEPS_DIR"/libffi-*.dylib "$DEPS_DIR"/*.a "$DEPS_DIR"/*.dylib; do
        if [ -f "$f" ]; then
          base=$(basename "$f")
          ext="${base##*.}"
          dest="$RELEASE_DIR/${base%.*}-$t.$ext"
          echo "Copying $f -> $dest"
          cp "$f" "$dest"
          copy_found=1
          # continue copying additional matches, don't break
        fi
      done
    fi
  fi

  if [ "$copy_found" -eq 0 ]; then
    echo "Warning: no libffi.* for $t in $LIB_PATH or $DEPS_DIR"
    echo "Contents of $LIB_PATH:" && ls -la "$LIB_PATH" || true
    echo "Contents of $DEPS_DIR:" && ls -la "$DEPS_DIR" || true
  fi
done

echo "Artifacts in $RELEASE_DIR"

echo "You can now use scripts/create_xcframework.sh to build an XCFramework from the built libraries."
