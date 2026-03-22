#include "crypto.hpp"
#include <cryptopp/gcm.h>
#include <cryptopp/aes.h>
#include <cryptopp/filters.h>
#include <cryptopp/secblock.h>
#include <cryptopp/osrng.h>
#include <cryptopp/cryptlib.h>
#include <vector>
#include <cstring>
#include <iostream>

namespace aegis {
namespace crypto {

static constexpr size_t AESGCM_TAG_SIZE = 16;

bool encrypt(const std::vector<uint8_t>& key,
             const std::vector<uint8_t>& nonce,
             const std::vector<uint8_t>& plaintext,
             std::vector<uint8_t>& ciphertext,
             std::vector<uint8_t>& tag) noexcept {
    try {
        using namespace CryptoPP;
        GCM<AES>::Encryption enc;
        enc.SetKeyWithIV(key.data(), key.size(), nonce.data(), nonce.size());

        std::vector<uint8_t> out;
        AuthenticatedEncryptionFilter aef(enc, new VectorSink(out), false, AESGCM_TAG_SIZE);
        ArraySource(plaintext.data(), plaintext.size(), true, new Redirector(aef));

        if(out.size() < AESGCM_TAG_SIZE) return false;
        // ciphertext is data without the tag appended by the filter
        size_t ct_size = out.size() - AESGCM_TAG_SIZE;
        ciphertext.assign(out.begin(), out.begin() + ct_size);
        tag.assign(out.begin() + ct_size, out.end());
        return true;
    } catch(const CryptoPP::Exception& e) {
        std::cerr << "crypto::encrypt exception: " << e.what() << std::endl;
        return false;
    } catch(...) {
        std::cerr << "crypto::encrypt unknown exception" << std::endl;
        return false;
    }
}

bool decrypt(const std::vector<uint8_t>& key,
             const std::vector<uint8_t>& nonce,
             const std::vector<uint8_t>& ciphertext,
             const std::vector<uint8_t>& tag,
             std::vector<uint8_t>& plaintext) noexcept {
    try {
        using namespace CryptoPP;
        GCM<AES>::Decryption dec;
        dec.SetKeyWithIV(key.data(), key.size(), nonce.data(), nonce.size());

        // combine ciphertext + tag as expected by the filter
        std::vector<uint8_t> combined;
        combined.reserve(ciphertext.size() + tag.size());
        combined.insert(combined.end(), ciphertext.begin(), ciphertext.end());
        combined.insert(combined.end(), tag.begin(), tag.end());

        std::vector<uint8_t> out;
        AuthenticatedDecryptionFilter adf(dec, new VectorSink(out), AuthenticatedDecryptionFilter::DEFAULT_FLAGS, AESGCM_TAG_SIZE);
        ArraySource(combined.data(), combined.size(), true, new Redirector(adf));

        if(adf.GetLastResult()){
            plaintext = std::move(out);
            return true;
        }
        return false;
    } catch(const CryptoPP::Exception& e) {
        std::cerr << "crypto::decrypt exception: " << e.what() << std::endl;
        return false;
    } catch(...) {
        std::cerr << "crypto::decrypt unknown exception" << std::endl;
        return false;
    }
}

} // namespace crypto
} // namespace aegis
