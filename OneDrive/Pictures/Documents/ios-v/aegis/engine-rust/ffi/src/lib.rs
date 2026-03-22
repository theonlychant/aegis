use std::ffi::{CStr, CString};
use std::os::raw::c_char;
use std::slice;
use libc::size_t;
use std::os::raw::c_int;
#[cfg(not(test))]
extern "C" {
    fn aegis_set_last_error(code: c_int, msg: *const c_char);
    fn aegis_log(msg: *const c_char);
}

#[inline]
fn set_last_error(code: c_int, msg: *const c_char) {
    #[cfg(not(test))]
    unsafe { aegis_set_last_error(code, msg) };
    #[cfg(test)]
    let _ = (code, msg);
}

#[inline]
fn log_msg(msg: *const c_char) {
    #[cfg(not(test))]
    unsafe { aegis_log(msg) };
    #[cfg(test)]
    let _ = msg;
}

#[no_mangle]
pub extern "C" fn aegis_canonicalize_url(input: *const c_char) -> *mut c_char {
    if input.is_null() {
        set_last_error(1, b"null input to canonicalize\0".as_ptr() as *const c_char);
        return std::ptr::null_mut();
    }
    let cstr = unsafe { CStr::from_ptr(input) };
    let s = match cstr.to_str() {
        Ok(v) => v,
        Err(_) => return std::ptr::null_mut(),
    };
    match scanner::canonicalize_url(s) {
        Some(out) => CString::new(out).unwrap().into_raw(),
        None => std::ptr::null_mut(),
    }
}

#[no_mangle]
pub extern "C" fn aegis_string_free(s: *mut c_char) {
    if s.is_null() { return }
    unsafe { let _ = CString::from_raw(s); }; // drop
}

#[no_mangle]
pub extern "C" fn aegis_scan_buffer(buf: *const u8, len: size_t) -> i32 {
    if buf.is_null() || len == 0 {
        set_last_error(1, b"null or empty buffer to scan\0".as_ptr() as *const c_char);
        return 0;
    }
    let slice = unsafe { slice::from_raw_parts(buf, len as usize) };
    scanner::scan_buffer(slice)
}

#[no_mangle]
pub extern "C" fn aegis_verify_rulepack(pubkey: *const u8, pubkey_len: size_t, data: *const u8, data_len: size_t, sig: *const u8, sig_len: size_t) -> i32 {
    if pubkey.is_null() || data.is_null() || sig.is_null() {
        set_last_error(1, b"null args to verify_rulepack\0".as_ptr() as *const c_char);
        return 0;
    }
    let p = unsafe { slice::from_raw_parts(pubkey, pubkey_len as usize) };
    let d = unsafe { slice::from_raw_parts(data, data_len as usize) };
    let s = unsafe { slice::from_raw_parts(sig, sig_len as usize) };
    if scanner::verify_rulepack_signature(p, d, s) { 1 } else { 0 }
}

#[no_mangle]
pub extern "C" fn aegis_scan_with_rulepack(buf: *const u8, len: size_t, rules_ptr: *const c_char) -> i32 {
    if buf.is_null() || len == 0 || rules_ptr.is_null() {
        set_last_error(1, b"null arg to scan_with_rulepack\0".as_ptr() as *const c_char);
        return 0;
    }
    let slice = unsafe { slice::from_raw_parts(buf, len as usize) };
    let cstr = unsafe { CStr::from_ptr(rules_ptr) };
    match cstr.to_str() {
        Ok(rjson) => scanner::scan_with_rulepack(slice, rjson),
        Err(_) => 0,
    }
}

#[no_mangle]
pub extern "C" fn aegis_verify_and_scan(pubkey: *const u8, pubkey_len: size_t, rulepack_ptr: *const c_char, _rulepack_len: size_t, sig: *const u8, sig_len: size_t, buf: *const u8, buf_len: size_t) -> i32 {
    if pubkey.is_null() || rulepack_ptr.is_null() || sig.is_null() || buf.is_null() {
        set_last_error(1, b"null arg to verify_and_scan\0".as_ptr() as *const c_char);
        return 0;
    }
    let p = unsafe { slice::from_raw_parts(pubkey, pubkey_len as usize) };
    let sigb = unsafe { slice::from_raw_parts(sig, sig_len as usize) };
    let data_slice = unsafe { slice::from_raw_parts(buf, buf_len as usize) };
    let cstr = unsafe { CStr::from_ptr(rulepack_ptr) };
    let rjson = match cstr.to_str() {
        Ok(s) => s,
        Err(_) => {
            set_last_error(1, b"invalid rulepack json string\0".as_ptr() as *const c_char);
            return 0;
        },
    };
    // verify signature over rulepack bytes
    let rulepack_bytes = &rjson.as_bytes();
    if !scanner::verify_rulepack_signature(p, rulepack_bytes, sigb) {
        set_last_error(2, b"rulepack signature verification failed\0".as_ptr() as *const c_char);
        return 0;
    }
    // proceed to scan
    let res = scanner::scan_with_rulepack(data_slice, rjson);
    if res == 0 {
        log_msg(b"scan returned no match\0".as_ptr() as *const c_char);
    }
    res
}


