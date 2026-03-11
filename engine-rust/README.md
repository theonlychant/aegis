engine-rust — Memory-safe scanner core (Rust)

Purpose

Holds the Rust-based scanning pipeline: parsing, URL canonicalization, YARA-like rule interpreter, archive traversal, and FFI-safe engine surface for Swift and C++ integration.

Next steps

- Initialize as a Cargo workspace.
- Add a `scanner` crate and `ffi` crate for bindings.
- Add CI rust-audit and cargo-fuzz entries.
