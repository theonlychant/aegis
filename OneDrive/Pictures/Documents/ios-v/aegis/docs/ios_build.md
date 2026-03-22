Building the Aegis native engine for iOS

This guide shows how to build the Rust FFI and package it as an XCFramework consumable by an Xcode project.

Prerequisites
- macOS with Xcode installed
- Rust toolchain and `rustup`
- `cargo` available in PATH
- (Optional) `cargo-lipo` for simplifying universal builds

1) Build Rust targets

Run:

```bash
scripts/build_rust_ios.sh
```

This will build the `ffi` crate for the `aarch64-apple-ios` and `x86_64-apple-ios` targets and copy artifacts into `target_ios/release`.

2) Create an XCFramework

Run:

```bash
scripts/create_xcframework.sh
```

This creates `xcframeworks/AegisEngine.xcframework` that you can drag into your Xcode project.

3) Link and call from Swift

- Add the XCFramework to your Xcode project/target (Embed & Sign or Do Not Embed based on binary type).
- Add the header `engine-c/include/aegis_ffi.h` to a bridging header or use Swift `@_silgen_name` declarations as shown in `DocumentScanner.swift`.
- Ensure the `.entitlements` files are attached to the correct targets and provisioning profiles include the network extension entitlement if you plan to use NE.

Notes
- Building for device architectures requires macOS and Xcode; CI on macOS runners (GitHub Actions `macos-latest`) can be used.
- For production, prefer building an XCFramework that includes arm64/arm64e slices for device and simulator slices for simulator.
