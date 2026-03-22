use std::ffi::CString;
use std::ptr;
use std::os::raw::{c_int, c_char};

// Provide test-only C symbol stubs so the integration test binary links
#[no_mangle]
pub extern "C" fn aegis_set_last_error(_code: c_int, _msg: *const c_char) {}

#[no_mangle]
pub extern "C" fn aegis_log(_msg: *const c_char) {}

use ffi::aegis_verify_and_scan;

#[test]
fn test_verify_and_scan_noop() {
    // Create a dummy rulepack JSON that matches substring "malicious"
    let rule_json = r#"{"rules":[{"id":"r1","pattern":"malicious"}]}"#;
    let c_rule = CString::new(rule_json).unwrap();
    // No signature (for this smoke test) and no pubkey; expect verify to fail and return 0
    let res = aegis_verify_and_scan(ptr::null(), 0, c_rule.as_ptr(), rule_json.len(), ptr::null(), 0, b"this contains malicious content\0".as_ptr(), 29);
    // We expect 0 because verification should fail when no pubkey/sig provided
    assert_eq!(res, 0);
}
