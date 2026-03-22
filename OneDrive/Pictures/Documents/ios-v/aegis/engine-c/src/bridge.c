#include <stdlib.h>
#include <string.h>
#include <stdio.h>
#include "../include/aegis_ffi.h"

// Forward declarations for Rust-provided symbols (linked at build time)
extern int aegis_scan_buffer(const unsigned char *buf, unsigned long len);
extern int aegis_scan_with_rulepack(const unsigned char *buf, unsigned long len, const char *rules_json);
extern int aegis_verify_rulepack(const unsigned char *pubkey, unsigned long pubkey_len, const unsigned char *data, unsigned long data_len, const unsigned char *sig, unsigned long sig_len);
extern int aegis_verify_and_scan(const unsigned char *pubkey, unsigned long pubkey_len, const char *rulepack_json, unsigned long rulepack_len, const unsigned char *sig, unsigned long sig_len, const unsigned char *buf, unsigned long buf_len);

const char* aegis_hello(void) {
    return "engine-c bridge";
}

int aegis_scan_buffer_bridge(const unsigned char *buf, unsigned long len) {
    if (!buf || len == 0) {
        aegis_set_last_error(AEGIS_ERR_NULL_ARG, "null or empty buffer");
        return -1;
    }
    int ret = aegis_scan_buffer(buf, len);
    if (ret <= 0) {
        aegis_set_last_error(AEGIS_ERR_INTERNAL, "scan returned no matches or error");
    }
    return ret;
}

int aegis_verify_rulepack_bridge(const unsigned char *pubkey, unsigned long pubkey_len, const unsigned char *data, unsigned long data_len, const unsigned char *sig, unsigned long sig_len) {
    if (!pubkey || !data || !sig) {
        aegis_set_last_error(AEGIS_ERR_NULL_ARG, "verify_rulepack null argument");
        return 0;
    }
    int ok = aegis_verify_rulepack(pubkey, pubkey_len, data, data_len, sig, sig_len);
    if (!ok) {
        aegis_set_last_error(AEGIS_ERR_VERIFY_FAILED, "rulepack signature verification failed");
    }
    return ok;
}

int aegis_scan_with_rulepack_bridge(const unsigned char *buf, unsigned long len, const char *rules_json) {
    return aegis_scan_with_rulepack(buf, len, rules_json);
}

int aegis_verify_and_scan_bridge(const unsigned char *pubkey, unsigned long pubkey_len, const char *rulepack_json, unsigned long rulepack_len, const unsigned char *sig, unsigned long sig_len, const unsigned char *buf, unsigned long buf_len) {
    if (!rulepack_json || !sig || !buf) {
        fprintf(stderr, "aegis_verify_and_scan_bridge: null argument\n");
        return -1;
    }
    return aegis_verify_and_scan(pubkey, pubkey_len, rulepack_json, rulepack_len, sig, sig_len, buf, buf_len);
}

// Thread-local last error info
static __thread int _aegis_last_err_code = 0;
static __thread char _aegis_last_err_msg[512] = {0};
static int _aegis_verbose = 0;
static FILE *_aegis_log_file = NULL;

void aegis_set_last_error(int code, const char *msg) {
    _aegis_last_err_code = code;
    if (msg) {
        strncpy(_aegis_last_err_msg, msg, sizeof(_aegis_last_err_msg)-1);
        _aegis_last_err_msg[sizeof(_aegis_last_err_msg)-1] = '\0';
    } else {
        _aegis_last_err_msg[0] = '\0';
    }
    if (_aegis_verbose) {
        if (!_aegis_log_file) {
            const char *path = getenv("AEGIS_LOG_PATH");
            if (path) _aegis_log_file = fopen(path, "a");
        }
        if (_aegis_log_file) {
            fprintf(_aegis_log_file, "[aegis][error] code=%d msg=%s\n", code, msg ? msg : "");
            fflush(_aegis_log_file);
        } else {
            fprintf(stderr, "[aegis][error] code=%d msg=%s\n", code, msg ? msg : "");
        }
    }
}

const char* aegis_last_error(void) {
    return _aegis_last_err_msg[0] ? _aegis_last_err_msg : NULL;
}

int aegis_last_error_code(void) {
    return _aegis_last_err_code;
}

void aegis_set_verbose(int v) {
    _aegis_verbose = v ? 1 : 0;
}

void aegis_log(const char *msg) {
    if (!msg) return;
    if (!_aegis_log_file) {
        const char *path = getenv("AEGIS_LOG_PATH");
        if (path) _aegis_log_file = fopen(path, "a");
    }
    if (_aegis_log_file) {
        fprintf(_aegis_log_file, "[aegis][log] %s\n", msg);
        fflush(_aegis_log_file);
    } else {
        fprintf(stderr, "[aegis][log] %s\n", msg);
    }
}
