encrypt - key derivation helper

This crate provides a small, focused helper to derive a 32-byte symmetric
key from an operator-supplied passphrase using Argon2id. The crate returns a
zeroized key wrapper so key material is cleared from memory on drop.

Usage (example)

```rust
use encrypt::derive_key_from_passphrase;

let pass = std::env::var("PROTECTION_PASSPHRASE").expect("set PROTECTION_PASSPHRASE");
let (key, salt) = derive_key_from_passphrase(&pass, None).unwrap();
// use &*key as bytes for AES-GCM / libs
```

Security notes

- Do NOT embed passphrases in source. Provide via secure environment variables
  or a secrets manager.
- Consider using platform KMS / keychain for production secrets instead of manual passphrases.
