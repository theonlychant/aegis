use std::ffi::CString;
use std::os::raw::c_char;
use std::ptr;
use std::slice;

extern "C" {
    fn aegis_verify_and_scan(pubkey: *const u8, pubkey_len: usize, rulepack_json: *const c_char, rulepack_len: usize, sig: *const u8, sig_len: usize, buf: *const u8, buf_len: usize) -> i32;
}

#[test]
fn test_verify_and_scan_noop() {
    // Create a dummy rulepack JSON that matches substring "malicious"
    let rule_json = r#"{"rules":[{"id":"r1","pattern":"malicious"}]}"#;
    let c_rule = CString::new(rule_json).unwrap();
    // No signature (for this smoke test) and no pubkey; expect verify to fail and return 0
    let res = unsafe { aegis_verify_and_scan(ptr::null(), 0, c_rule.as_ptr(), rule_json.len(), ptr::null(), 0, b"this contains malicious content\0".as_ptr(), 29) };
    // We expect 0 because verification should fail when no pubkey/sig provided
    assert_eq!(res, 0);
}
