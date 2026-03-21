//! encrypt — small helper crate to derive a symmetric protection key
//! from a passphrase using Argon2id. Designed for use as a library in
//! server or local tooling. The key is returned as a zeroized Vec<u8>.

use argon2::{Argon2, PasswordHasher, Params, password_hash::{SaltString, PasswordHash, PasswordVerifier}};
use rand::rngs::OsRng;
use zeroize::Zeroize;

/// Derive a 32-byte key (suitable for AES-256) from a passphrase using Argon2id.
///
/// - `passphrase`: secret string provided by operator (from secure env or prompt)
/// - `salt_opt`: optional salt bytes; if None a new random salt is generated and returned
///
/// Returns `(key, salt)` where `key` is a zeroize-able Vec<u8> and `salt` is the salt used.
pub fn derive_key_from_passphrase(passphrase: &str, salt_opt: Option<&[u8]>) -> Result<(ZeroizingKey, Vec<u8>), anyhow::Error> {
    // Recommended Argon2 parameters for interactive logins: moderate memory & time
    let params = Params::new(65536, 3, 1, None)?; // 64 MiB, 3 iterations, 1 lane
    let argon2 = Argon2::new(argon2::Algorithm::Argon2id, argon2::Version::V0x13, params);

    let salt_bytes = match salt_opt {
        Some(s) => s.to_vec(),
        None => {
            let salt = SaltString::generate(&mut OsRng);
            salt.as_bytes().to_vec()
        }
    };

    // Use the raw Argon2 primitive (not the password-hash format) to get deterministic output
    let mut out = vec![0u8; 32];
    argon2.hash_password_into(passphrase.as_bytes(), &salt_bytes, &mut out)?;

    Ok((ZeroizingKey(out), salt_bytes))
}

/// Wrapper type that zeroizes its contents on drop.
pub struct ZeroizingKey(pub(crate) Vec<u8>);

impl Zeroize for ZeroizingKey {
    fn zeroize(&mut self) {
        self.0.zeroize();
    }
}

impl Drop for ZeroizingKey {
    fn drop(&mut self) {
        self.zeroize();
    }
}

impl std::ops::Deref for ZeroizingKey {
    type Target = [u8];
    fn deref(&self) -> &Self::Target { &self.0 }
}

/// Generate a fresh random salt (16 bytes).
pub fn generate_salt() -> Vec<u8> {
    let mut s = vec![0u8; 16];
    getrandom::getrandom(&mut s).expect("getrandom failed");
    s
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn derive_same() {
        let pass = "correct horse battery staple";
        let (k1, s) = derive_key_from_passphrase(pass, None).unwrap();
        let (k2, _) = derive_key_from_passphrase(pass, Some(&s)).unwrap();
        assert_eq!(&*k1, &*k2);
    }
}
