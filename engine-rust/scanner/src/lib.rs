use url::Url;

pub fn canonicalize_url(s: &str) -> Option<String> {
    Url::parse(s).ok().map(|u| u.into_string())
}

// Simple scanning stub: returns 1 for malicious, 0 for clean.
pub fn scan_buffer(buf: &[u8]) -> i32 {
    if let Ok(s) = std::str::from_utf8(&buf[..std::cmp::min(buf.len(), 4096)]) {
        if s.to_lowercase().contains("malicious") {
            return 1;
        }
    }
    0
}

use ring::signature::UnparsedPublicKey;
use aho_corasick::AhoCorasick;
use serde::Deserialize;

#[derive(Deserialize)]
pub struct Rule {
    pub id: String,
    pub pattern: String,
    pub r#type: Option<String>,
}

#[derive(Deserialize)]
pub struct RulePack {
    pub version: String,
    pub rules: Vec<Rule>,
}

pub fn scan_with_rulepack(buf: &[u8], rules_json: &str) -> i32 {
    if let Ok(rp) = serde_json::from_str::<RulePack>(rules_json) {
        let patterns: Vec<&str> = rp.rules.iter().map(|r| r.pattern.as_str()).collect();
        let ac = AhoCorasick::new(&patterns);
        let hay = if buf.len() > 0 { buf } else { b"" };
        let count = ac.find_iter(hay).count();
        return count as i32;
    }
    0
}

/// Verify rule pack signature with a public key (DER-encoded) and signature bytes (ASN.1)
pub fn verify_rulepack_signature(pubkey_der: &[u8], data: &[u8], sig: &[u8]) -> bool {
    let pk = UnparsedPublicKey::new(&ring::signature::ECDSA_P256_SHA256_ASN1, pubkey_der);
    match pk.verify(data, sig) {
        Ok(()) => true,
        Err(_) => false,
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    use ring::rand::SystemRandom;
    use ring::signature::{EcdsaKeyPair, ECDSA_P256_SHA256_ASN1_SIGNING};

    #[test]
    fn test_canonicalize() {
        let u = "https://Example.com/path";
        let c = canonicalize_url(u).unwrap();
        assert!(c.to_lowercase().contains("example.com"));
    }

    #[test]
    fn test_verify_rulepack_signature() {
        let data = b"sample rule pack data";
        let rng = SystemRandom::new();
        let pkcs8 = EcdsaKeyPair::generate_pkcs8(&ECDSA_P256_SHA256_ASN1_SIGNING, &rng).unwrap();
        let key_pair = EcdsaKeyPair::from_pkcs8(&ECDSA_P256_SHA256_ASN1_SIGNING, pkcs8.as_ref()).unwrap();
        let sig = key_pair.sign(&rng, data).unwrap();
        let pubkey_der = key_pair.public_key().as_ref();
        let ok = verify_rulepack_signature(pubkey_der, data, sig.as_ref());
        assert!(ok, "signature verification should succeed");
    }
}
