#pragma once
#include <cstddef>
#include <stdint.h>

#ifdef __cplusplus
extern "C" {
#endif

// Encrypts `in` of length `in_len` using `key` and `nonce`.
// On success returns 0 and sets `out_len` and `tag_len` appropriately.
// `out` should be a caller-provided buffer of sufficient size or NULL to query required size.
int aegis_encrypt(const uint8_t* in, size_t in_len,
                  uint8_t* out, size_t* out_len,
                  uint8_t* tag, size_t* tag_len,
                  const uint8_t* key, size_t key_len,
                  const uint8_t* nonce, size_t nonce_len) noexcept;

int aegis_decrypt(const uint8_t* in, size_t in_len,
                  const uint8_t* tag, size_t tag_len,
                  uint8_t* out, size_t* out_len,
                  const uint8_t* key, size_t key_len,
                  const uint8_t* nonce, size_t nonce_len) noexcept;

#ifdef __cplusplus
}
#endif
