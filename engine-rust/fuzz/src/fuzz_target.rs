#![no_main]
use libfuzzer_sys::fuzz_target;
use scanner::scan_with_rulepack;

fuzz_target!(|data: &[u8]| {
    // Use a small sample rulepack for fuzzing
    let rules = r#"{\"version\":\"1\",\"rules\": [{\"id\":\"r1\", \"pattern\": \"malicious\"}]}"#;
    let _ = scan_with_rulepack(data, rules);
});
