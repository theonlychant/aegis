Aegis — iPhone Security Platform

Overview

Aegis is a modular iPhone security platform focused on malicious URL/domain blocking, phishing detection, imported-file scanning, device integrity checks, and optional network/content filtering. The project uses Swift (iOS app), Rust/C++/C (native engines), and Go (backend services).

Repository layout

- ios-app/                 — Swift iOS application shell and UI
- ios-extensions/          — Network Extension and URL/content filter extensions
  - content-filter/        — NE content filter stubs
  - url-filter/            — iOS 26+ URL filtering path
- engine-rust/             — Rust scanning and rule engine (memory-safe)
- engine-cpp/              — C++ performance heuristics and matchers
- engine-c/                — C ABI shims and minimal helpers
- backend-go/              — Go services: reputation, rule distro, telemetry
- shared-schemas/          — JSON/Protobuf/OpenAPI schemas
- rules/                   — Detection rules and sample corpora
- perf/                    — Benchmark harnesses and results
- fuzz/                    — Fuzzing harnesses for parsers
- docs/                    — Architecture, threat model, compliance

Getting started

1. Pick a module to implement first (suggestion: `engine-rust` + `backend-go` for MVP).
2. Follow README in each module for scaffolding details and development commands.

Next steps

- Scaffold module skeletons (READMEs created).
- Implement CI, signing, and initial rule pack.

License: (TBD)
