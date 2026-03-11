#ifndef AEGIS_FFI_H
#define AEGIS_FFI_H

#ifdef __cplusplus
extern "C" {
#endif

char *aegis_canonicalize_url(const char *input);
void aegis_string_free(char *s);
const char* aegis_hello(void);
int aegis_scan_buffer(const unsigned char *buf, unsigned long len);
int aegis_verify_rulepack(const unsigned char *pubkey, unsigned long pubkey_len, const unsigned char *data, unsigned long data_len, const unsigned char *sig, unsigned long sig_len);
int aegis_verify_and_scan(const unsigned char *pubkey, unsigned long pubkey_len, const char *rulepack_json, unsigned long rulepack_len, const unsigned char *sig, unsigned long sig_len, const unsigned char *buf, unsigned long buf_len);
// Bridge functions implemented in engine-c that forward to Rust FFI when available
int aegis_scan_buffer_bridge(const unsigned char *buf, unsigned long len);
int aegis_verify_rulepack_bridge(const unsigned char *pubkey, unsigned long pubkey_len, const unsigned char *data, unsigned long data_len, const unsigned char *sig, unsigned long sig_len);
int aegis_scan_with_rulepack(const unsigned char *buf, unsigned long len, const char *rules_json);
int aegis_verify_and_scan_bridge(const unsigned char *pubkey, unsigned long pubkey_len, const char *rulepack_json, unsigned long rulepack_len, const unsigned char *sig, unsigned long sig_len, const unsigned char *buf, unsigned long buf_len);

// Error reporting API
typedef enum {
	AEGIS_OK = 0,
	AEGIS_ERR_NULL_ARG = 1,
	AEGIS_ERR_VERIFY_FAILED = 2,
	AEGIS_ERR_INTERNAL = 3
} aegis_error_t;

// Return the last thread-local error message (null if none)
const char* aegis_last_error(void);
// Return the last thread-local error code
int aegis_last_error_code(void);

// Set the last thread-local error (callable from other languages)
void aegis_set_last_error(int code, const char *msg);

// Enable verbose logging (non-zero to enable)
void aegis_set_verbose(int v);

// Log a message via bridge logger
void aegis_log(const char *msg);

// Simple checked wrapper API (returns aegis_error_t)
int aegis_scan_buffer_checked(const unsigned char *buf, unsigned long len);

#ifdef __cplusplus
}
#endif

#endif // AEGIS_FFI_H
