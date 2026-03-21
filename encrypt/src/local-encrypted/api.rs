// engine-rust/ffi surface idea
// Swift fetches or unwraps DEK from the keychain/secure enclave side
// passes it into Rust only for the duration of one operation
pub fn protect_cached_rules(dek_bytes: [u8; 32], rules: &[u8], aad: &[u8]) -> Result<Vec<u8>> {
    let dek = DataEncryptionKey::new(dek_bytes);
    encrypt_blob(&dek, rules, aad)
}
pub fn open_cached_rules(dek_bytes: [u8; 32], blob: &[u8], aad: &[u8]) -> Result<Vec<u8>> {
    let dek = DataEncryptionKey::new(dek_bytes);
    decrypt_blob(&dek, blob, aad)
}