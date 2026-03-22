#!/usr/bin/env bash
set -euo pipefail

# Local integration test:
# - build and run backend
# - fetch /rules/latest
# - build rust ffi for host
# - build engine-cpp linking to rust ffi and run demo

PORT=8081
BACKEND_BIN=build/aegis-backend
RUST_FFIPATH=engine-rust/ffi/target/release

mkdir -p build

echo "Building backend..."
(cd backend-go && go build -o ../$BACKEND_BIN main.go)

echo "Starting backend on port $PORT..."
$BACKEND_BIN &
BACK_PID=$!
sleep 1

echo "Fetching signed rule pack..."
curl -s "http://localhost:$PORT/rules/latest" -o /tmp/rules.json
jq -r '.rule' /tmp/rules.json | base64 --decode > /tmp/rule.bin
jq -r '.signature' /tmp/rules.json | base64 --decode > /tmp/rule.sig
jq -r '.pubkey' /tmp/rules.json | base64 --decode > /tmp/pubkey.der

# Build Rust FFI for host
echo "Building Rust ffi (host)..."
(cd engine-rust/ffi && cargo build --release)

# Locate produced library (libffi.*)
if [ -f engine-rust/ffi/target/release/libffi.so ]; then
  RUST_LIB=engine-rust/ffi/target/release/libffi.so
elif [ -f engine-rust/ffi/target/release/libffi.dylib ]; then
  RUST_LIB=engine-rust/ffi/target/release/libffi.dylib
else
  echo "Could not find rust ffi library in engine-rust/ffi/target/release"
  kill $BACK_PID || true
  exit 1
fi

echo "Found rust lib: $RUST_LIB"

# Build engine-cpp and pass RUST_FFI_LIB
mkdir -p engine-cpp/build
cd engine-cpp/build
cmake -DRUST_FFI_LIB=$(realpath ../../$RUST_LIB) ..
cmake --build .

echo "Running engine-cpp demo..."
./engine_cpp_run || true

# Cleanup
kill $BACK_PID || true

echo "Local integration test complete."
