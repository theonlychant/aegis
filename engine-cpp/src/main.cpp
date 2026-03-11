#include <iostream>
#include <fstream>
#include <vector>
#include <string>
#include <cstring>
#include <unistd.h>
#include <limits.h>
#include <openssl/evp.h>
#include <openssl/pem.h>
#include <openssl/err.h>
#include <openssl/sha.h>
#include "aegis_ffi.h"

static std::vector<unsigned char> readFileBytes(const std::string &path) {
    std::ifstream f(path, std::ios::binary);
    if (!f) return {};
    return std::vector<unsigned char>((std::istreambuf_iterator<char>(f)), std::istreambuf_iterator<char>());
}

static std::string hex(const unsigned char *buf, size_t len) {
    static const char *hexchars = "0123456789abcdef";
    std::string out; out.reserve(len*2);
    for (size_t i=0;i<len;i++){
        out.push_back(hexchars[(buf[i]>>4)&0xF]);
        out.push_back(hexchars[buf[i]&0xF]);
    }
    return out;
}

static bool verify_ecdsa_der_pubkey_signature(const std::vector<unsigned char>& pubkey_der, const std::vector<unsigned char>& payload, const std::vector<unsigned char>& sig_der) {
    const unsigned char *p = pubkey_der.data();
    EVP_PKEY *pkey = d2i_PUBKEY(NULL, &p, (long)pubkey_der.size());
    if (!pkey) return false;
    EVP_MD_CTX *mdctx = EVP_MD_CTX_new();
    bool ok = false;
    if (EVP_DigestVerifyInit(mdctx, NULL, EVP_sha256(), NULL, pkey) == 1) {
        if (EVP_DigestVerifyUpdate(mdctx, payload.data(), payload.size()) == 1) {
            if (EVP_DigestVerifyFinal(mdctx, sig_der.data(), sig_der.size()) == 1) {
                ok = true;
            }
        }
    }
    EVP_MD_CTX_free(mdctx);
    EVP_PKEY_free(pkey);
    return ok;
}

int main(int argc, char **argv) {
    const char* s = aegis_hello();
    std::cout << "engine-cpp calling C bridge: " << (s ? s : "<null>") << std::endl;

    // Self integrity check: compute SHA256 of this executable and compare to ../rules/self.sha256 if present
    char exePath[PATH_MAX] = {0};
    ssize_t r = readlink("/proc/self/exe", exePath, sizeof(exePath)-1);
    if (r > 0) exePath[r] = '\0';
    auto selfBytes = readFileBytes(std::string(exePath));
    if (!selfBytes.empty()) {
        unsigned char digest[SHA256_DIGEST_LENGTH];
        SHA256(selfBytes.data(), selfBytes.size(), digest);
        std::string got = hex(digest, SHA256_DIGEST_LENGTH);
        auto expectBytes = readFileBytes("../rules/self.sha256");
        if (!expectBytes.empty()) {
            std::string expect(expectBytes.begin(), expectBytes.end());
            // trim whitespace
            while(!expect.empty() && isspace((unsigned char)expect.back())) expect.pop_back();
            if (expect != got) {
                std::cerr << "Executable integrity check failed: expected=" << expect << " got=" << got << "\n";
                std::cerr << "Aborting due to integrity failure." << std::endl;
                return 2;
            } else {
                std::cout << "Executable integrity check passed." << std::endl;
            }
        } else {
            std::cout << "No self.sha256 manifest found; skipping integrity check." << std::endl;
        }
    }

    // Load example rulepack JSON, signature, and public key (files expected in ../rules/)
    auto rulebuf = readFileBytes("../rules/example-rule.json");
    auto sigbuf = readFileBytes("../rules/example-rule.sig");
    auto pubkeybuf = readFileBytes("../rules/pubkey.der");

    if (rulebuf.empty() || sigbuf.empty() || pubkeybuf.empty()) {
        std::cout << "rule, signature, or pubkey file missing; falling back to simple scan" << std::endl;
        extern int aegis_scan_buffer(const unsigned char *buf, unsigned long len);
        const char *test = "this contains malicious content";
        int res = aegis_scan_buffer((const unsigned char*)test, strlen(test));
        std::cout << "aegis_scan_buffer returned: " << res << std::endl;
        return 0;
    }

    // Verify signature over rulepack (server signs version+"\n"+rule bytes; attempt naive verification over rule bytes)
    bool sig_ok = verify_ecdsa_der_pubkey_signature(pubkeybuf, rulebuf, sigbuf);
    if (!sig_ok) {
        std::cerr << "Rulepack signature verification failed. Aborting." << std::endl;
        return 3;
    }
    std::cout << "Rulepack signature verified." << std::endl;

    // Call combined verify-and-scan bridge (pubkey DER, rulepack JSON cstring, signature, sample buffer)
    const char *ruleptr = rulebuf.empty() ? nullptr : reinterpret_cast<const char*>(rulebuf.data());
    unsigned long rulelen = (unsigned long)rulebuf.size();

    int res = aegis_verify_and_scan_bridge(pubkeybuf.data(), pubkeybuf.size(), ruleptr, rulelen, sigbuf.data(), sigbuf.size(), (const unsigned char*)"this contains malicious content", strlen("this contains malicious content"));
    std::cout << "aegis_verify_and_scan_bridge returned: " << res << std::endl;
    return 0;
}
