#include "bridge.h"
#include "../crypto/crypto.hpp"
#include <vector>
#include <cstring>

int aegis_encrypt(const uint8_t* in, size_t in_len,
                  uint8_t* out, size_t* out_len,
                  uint8_t* tag, size_t* tag_len,
                  const uint8_t* key, size_t key_len,
                  const uint8_t* nonce, size_t nonce_len) noexcept {
#if defined(__APPLE__)
    extern "C" int32_t aegis_encrypt_apple(const uint8_t*, size_t, uint8_t*, int*, uint8_t*, int*, const uint8_t*, size_t, const uint8_t*, size_t);
    // adapt size_t/int pointers for the Swift bridge
    int outLen = out ? (int)*out_len : 0;
    int tagLen = tag ? (int)*tag_len : 0;
    int32_t rc = aegis_encrypt_apple(in, (int)in_len, out, &outLen, tag, &tagLen, key, (int)key_len, nonce, (int)nonce_len);
    if(out && out_len) *out_len = (size_t)outLen;
    if(tag && tag_len) *tag_len = (size_t)tagLen;
    return rc;
#else
    if(!in || !key || !nonce || !out_len || !tag_len) return -1;
    std::vector<uint8_t> k(key, key + key_len);
    std::vector<uint8_t> n(nonce, nonce + nonce_len);
    std::vector<uint8_t> pt(in, in + in_len);
    std::vector<uint8_t> ct;
    std::vector<uint8_t> t;
    bool ok = aegis::crypto::encrypt(k, n, pt, ct, t);
    if(!ok) return -2;
    if(!out) {
        *out_len = ct.size();
        *tag_len = t.size();
        return 0;
    }
    if(*out_len < ct.size() || *tag_len < t.size()) return -3;
    std::memcpy(out, ct.data(), ct.size());
    std::memcpy(tag, t.data(), t.size());
    *out_len = ct.size();
    *tag_len = t.size();
    return 0;
}

int aegis_decrypt(const uint8_t* in, size_t in_len,
                  const uint8_t* tag, size_t tag_len,
                  uint8_t* out, size_t* out_len,
                  const uint8_t* key, size_t key_len,
                  const uint8_t* nonce, size_t nonce_len) noexcept {
#if defined(__APPLE__)
    extern "C" int32_t aegis_decrypt_apple(const uint8_t*, int, const uint8_t*, int, uint8_t*, int*, const uint8_t*, int, const uint8_t*, int);
    int outLen = out ? (int)*out_len : 0;
    int32_t rc = aegis_decrypt_apple(in, (int)in_len, tag, (int)tag_len, out, &outLen, key, (int)key_len, nonce, (int)nonce_len);
    if(out && out_len) *out_len = (size_t)outLen;
    return rc;
#else
    if(!in || !key || !nonce || !out_len) return -1;
    std::vector<uint8_t> k(key, key + key_len);
    std::vector<uint8_t> n(nonce, nonce + nonce_len);
    std::vector<uint8_t> ct(in, in + in_len);
    std::vector<uint8_t> t(tag, tag + tag_len);
    std::vector<uint8_t> pt;
    bool ok = aegis::crypto::decrypt(k, n, ct, t, pt);
    if(!ok) return -2;
    if(!out) {
        *out_len = pt.size();
        return 0;
    }
    if(*out_len < pt.size()) return -3;
    std::memcpy(out, pt.data(), pt.size());
    *out_len = pt.size();
    return 0;
}
