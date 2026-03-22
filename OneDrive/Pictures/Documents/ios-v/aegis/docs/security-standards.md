Security engineering standards and checklist

- Signed rule packs with signature verification
- Reproducible builds for engine components
- Fuzz all parsers and integrate cargo-fuzz / libFuzzer
- ASan/UBSan/TSan in CI for C/C++ components
- cargo-audit and dependency review for Rust
- SAST and dependency scanning for Go
- Crash-safe rollback for rule updates
- Privacy-minimized telemetry; opt-in defaults
- Use App Attest / DeviceCheck where applicable
