#!/usr/bin/env bash
set -euo pipefail

# Create an XCFramework from prebuilt static libraries for iOS.
# Requires Xcode's xcodebuild tool and the static libs produced by build_rust_ios.sh

RELEASE_DIR="target_ios/release"
OUT_DIR="xcframeworks"
FRAMEWORK_NAME="AegisEngine"

mkdir -p "$OUT_DIR"

LIB_AARCH64="$RELEASE_DIR/libffi-aarch64-apple-ios.a"
LIB_X86_64="$RELEASE_DIR/libffi-x86_64-apple-ios.a"

if [ ! -f "$LIB_AARCH64" ] || [ ! -f "$LIB_X86_64" ]; then
  echo "Missing expected static libraries in $RELEASE_DIR"
  exit 1
fi

xcodebuild -create-xcframework \
  -library "$LIB_AARCH64" -headers "engine-c/include" \
  -library "$LIB_X86_64" -headers "engine-c/include" \
  -output "$OUT_DIR/${FRAMEWORK_NAME}.xcframework"

echo "Created $OUT_DIR/${FRAMEWORK_NAME}.xcframework"
