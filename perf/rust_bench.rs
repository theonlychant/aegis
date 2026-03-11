use std::fs;
use std::time::Instant;

fn main() {
    // Load sample corpus
    let s = fs::read_to_string("../rules/corpora/malicious.txt").expect("read corpus");
    let data = s.repeat(1000); // make it larger
    let buf = data.as_bytes();

    // Example rulepack: look for "malicious" pattern
    let rules = r#"{"version":"1","rules":[{"id":"r1","pattern":"malicious"}]}"#;

    // Call into the Rust scanner via the scanner crate directly (in-process)
    let start = Instant::now();
    let mut hits = 0;
    for _ in 0..50 {
        hits += aegis_bench::scan_with_rulepack(buf, rules);
    }
    let elapsed = start.elapsed();
    println!("Total hits: {} elapsed: {:?}", hits, elapsed);
}

// A small helper crate wrapper to call the scanner crate functions.
mod aegis_bench {
    pub fn scan_with_rulepack(buf: &[u8], rules_json: &str) -> i32 {
        aegis_scan::scan_with_rulepack(buf, rules_json)
    }
}
