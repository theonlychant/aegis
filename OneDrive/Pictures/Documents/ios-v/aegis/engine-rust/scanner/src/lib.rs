use url::Url;

pub fn canonicalize_url(s: &str) -> Option<String> {
    Url::parse(s).ok().map(|u| u.into_string())
}

// Simple scanning stub: returns 1 for malicious, 0 for clean.
pub fn scan_buffer(buf: &[u8]) -> i32 {
    let slice = if buf.len() > 0 { &buf[..std::cmp::min(buf.len(), MAX_SCAN_BYTES)] } else { b"" };
    if let Ok(s) = std::str::from_utf8(slice) {
        if s.to_lowercase().contains("malicious") {
            return 1;
        }
    }
    0
}

use ring::signature::UnparsedPublicKey;
use ring::signature::KeyPair;
use aho_corasick::AhoCorasick;
use serde::Deserialize;

// Limits to mitigate unbounded inputs (prevent DoS / unsound public API usage)
const MAX_RULES: usize = 1000;
const MAX_PATTERN_LEN: usize = 1024; // bytes per pattern
const MAX_RULEPACK_SIZE: usize = 256 * 1024; // 256 KB max JSON rulepack
const MAX_SCAN_BYTES: usize = 16 * 1024; // 16 KB max scanning window

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
    // Basic size checks
    if rules_json.len() == 0 || rules_json.len() > MAX_RULEPACK_SIZE {
        return 0;
    }

    let rp = match serde_json::from_str::<RulePack>(rules_json) {
        Ok(v) => v,
        Err(_) => return 0,
    };

    if rp.rules.len() == 0 || rp.rules.len() > MAX_RULES {
        return 0;
    }

    // Collect patterns with per-pattern length checks
    let mut owned: Vec<String> = Vec::with_capacity(rp.rules.len());
    for r in rp.rules.iter() {
        let p = r.pattern.as_bytes();
        if p.is_empty() || p.len() > MAX_PATTERN_LEN {
            return 0;
        }
        owned.push(r.pattern.clone());
    }

    let patterns_ref: Vec<&str> = owned.iter().map(|s| s.as_str()).collect();
    let ac = AhoCorasick::new(&patterns_ref);

    let hay = if buf.len() > 0 { &buf[..std::cmp::min(buf.len(), MAX_SCAN_BYTES)] } else { b"" };
    let count = ac.find_iter(hay).count();
    count as i32
}

/// Verify rule pack signature with a public key (DER-encoded) and signature bytes (ASN.1)
pub fn verify_rulepack_signature(pubkey_der: &[u8], data: &[u8], sig: &[u8]) -> bool {
    if pubkey_der.is_empty() || pubkey_der.len() > 4096 || sig.is_empty() {
        return false;
    }
    let pk = UnparsedPublicKey::new(&ring::signature::ECDSA_P256_SHA256_ASN1, pubkey_der);
    pk.verify(data, sig).is_ok()
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
        let key_pair = EcdsaKeyPair::from_pkcs8(&ECDSA_P256_SHA256_ASN1_SIGNING, pkcs8.as_ref(), &rng).unwrap();
        let sig = key_pair.sign(&rng, data).unwrap();
        let pubkey_der = key_pair.public_key().as_ref();
        let ok = verify_rulepack_signature(pubkey_der, data, sig.as_ref());
        assert!(ok, "signature verification should succeed");
    }
}
