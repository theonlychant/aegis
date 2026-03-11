Production hardening checklist

Backend
- Serve TLS: set `TLS_CERT_PATH` and `TLS_KEY_PATH` and run on port 8443.
- Require `X-API-KEY` for sensitive endpoints; set `API_KEY` env var.
- Store signing keys in Vault (set `VAULT_ADDR`, `VAULT_TOKEN`, and `VAULT_SECRET_PATH`).
- Use `rules/rotate` endpoint to rotate signed rule keys. Do key rotation via CI/CD or secure admin console.
- Protect backend with firewall, rate-limiting, monitoring, and WAF.

Key management
- Use KMS/Vault for private keys. Do not store private keys in repo or plain files in production.
- Implement key rotation and graceful key rollover mechanism (publish new pubkey alongside old key id).
- Maintain key metadata: key id (kid), creation time, rotation schedule.

App Attest
- Implement real App Attest verification flow using Apple's attestation APIs.
- Keep attestation verification logs and rate-limit attestation requests to avoid abuse.

On-device
- Use Secure Enclave for device-private keys via CryptoKit / SecureEnclave APIs.
- Use Keychain access control lists and require biometrics for high-value operations.
- Implement jailbreak/tamper checks and disable sensitive features on tampered devices.

Testing
- Add `cargo-audit` and `govulncheck` to CI.
- Add CodeQL and SAST (Semgrep) scanning to CI.
- Integrate fuzzing (cargo-fuzz for Rust; libFuzzer for C/C++). Maintain fuzz corpora.
- Configure ASan/UBSan for C/C++ in CI (linux runners); configure CI to fail on sanitizer errors.

Operational
- Provide signed rule pack versioning and atomic swap with rollback: download -> verify signature -> write to temporary file -> move into place.
- Backup previous rule pack for rollback.
- Implement telemetry opt-in and minimize PII.
