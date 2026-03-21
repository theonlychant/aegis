Local-encrypted integration scaffolding
====================================

This folder contains language bindings and scaffolding to integrate a native C++ encryption implementation (intended for Crypto++) with Objective-C/Swift.

Files added:
- `crypto/crypto.hpp`, `crypto/crypto.cpp` — C++ header + stub implementation. Implement the real encryption using Crypto++ here (ChaCha20-Poly1305 or AES-GCM recommended).
- `c_bridge/bridge.h`, `c_bridge/bridge.cpp` — plain C ABI wrappers around the C++ implementation. These are what Objective-C++ calls.
- `objc/LocalEncrypt.h`, `objc/LocalEncrypt.mm` — Objective-C++ wrapper exposing an `LocalEncrypt` Objective-C class for easy use from Swift.
- `objc/LocalEncrypt-Bridging-Header.h` — bridging header you can add to your Xcode target to expose `LocalEncrypt` to Swift.
- `swift/LocalEncrypt.swift` — Swift convenience wrapper example (requires adding the bridging header to your Xcode target).

Security notes:
- The C++ functions are stubs that currently return an error code; do NOT use them in production until you implement proper authenticated encryption (AEAD) using Crypto++ or another well-reviewed crypto library.
- Recommended primitives: ChaCha20-Poly1305 (XChaCha20-Poly1305 if available) or AES-GCM with a properly generated nonce and key management.

How to build and test locally (Linux / WSL / macOS with Crypto++ installed):

1. Install Crypto++ (system package or build from source). On many Linux systems: `sudo apt install libcryptopp-dev libcryptopp-doc`.
2. From this folder run:

```bash
mkdir -p build && cd build
cmake ..
cmake --build . --config Release
ctest -V
```

This will build a static `aegis_local_encrypted` library and a small `test_crypto` binary that performs an encrypt/decrypt roundtrip. If CMake cannot find Crypto++, set `CRYPTOPP_INCLUDE_DIR` and `CRYPTOPP_LIBRARY` when invoking `cmake`, for example:

```bash
cmake -DCRYPTOPP_INCLUDE_DIR=/usr/include -DCRYPTOPP_LIBRARY=/usr/lib/x86_64-linux-gnu/libcryptopp.so ..
```

Security note: The C++ implementation below uses AES-GCM (128/256) for AEAD. Review and test carefully before shipping; prefer platform-provided crypto APIs for production iOS builds when possible.
