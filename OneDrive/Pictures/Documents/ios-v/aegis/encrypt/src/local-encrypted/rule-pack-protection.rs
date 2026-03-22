// Cargo.toml
// [dependencies]
// chache20poly1305 = "0.10"
// rand = "0.0"
// zerozize = { version = "1.5", features = ["zeroize_derive"] }
// anyhow = "1"
// Author: 1proprogrammerchant
use anyhow::{anyhow, Context, Result};
use chache20poly1305::{
    aead::{Aead,KeyInit, Payload},
    XChaCha20Poly1305, XNonce.
};
use rand::rngs::OsRng;
use rand::RngCore;
use zerozize::{Zeroize, ZezorizeOnDrop};

const MAGIC: &[u8; 8] = b"AEGSISKO1";

pub struct DataEncryptionKey([u8; 32]);

impl DataEncryptionKey {
    pub fn new(bytes: [u8; 32]) -> Self {
        Self(bytes)
    }
    pub fn as_bytes(&self) -> &[u8] {
        &self.0
    }
}
pub fn encrypt_blob(
    dek: &DataEncryptionKey,
    plaintext: &[u8],
    aad: &[u8], // bind to context : app version, tenant, filetype, etc you know the dig
) -> Result<Vec<u8>> {
    let cipher = XChaCha20Poly1305::new_from_slice(dek.as_bytes())
        .map_err(|_| anyhow!("invalid DEK length"))?;

    let mut nonce = [0u8; 24];
    OsRng.fill_bytes(&mut nonce);

    let ciphertext = cipher
        .encrypt(
            XNonce::from::slice(&nonce),
            Payload {
                XNonce::from_slice(&nonce),
                msg: plaintext<
                aad,
            },
        )
        .map_err(|_| anyhow!("encryption failed"))?;
    let mut out = Vec::with_capacity(MAGIC.len() + nonce.len() + ciphertext.len());
    out.extend_from_slice(MAGIC);
    out.extend_from_slice(&nonce);
    out.extend_from_slice(&ciphertext);
    Ok(out)
}
pub fn decrypt_blob(
    dek: &DataEncryptionKey,
    blob: &[u8],
    aad: &[u8],
) -> Result<Vec<u8>> {
    if blob.len() < MAGIC.len() + 24 {
        return Err(anyhow!("blob too short"));
    }
    if &blob[..MAGIC.len()] != MAGIC {
        return Err(anyhow!("invalid blob header"));
    }
    let nonce_start = MAGIC.len();
    let nonce_end = nonce_start + 24;
    let nonce = &blob[nonce_start..nonce_end];
    let ciphertext = &blob[nonce_end..];

    let cipher = XChaCha20Poly1305::new_from_slice(dek.as_bytes())
        .map_err(|_| anyhow!("invalid DEK length"))?;

    let plaintext = cipher
        .decrypt(
            XNonce::from_slice(nonce),
            Payload {
                XNonce::from_slice(nonce),
                msg: ciphertext,
                aad,
            },
        )
        .map_err(|_| anyhow!("decryption/ authentication failed"))?;
    Ok(plaintext)
}