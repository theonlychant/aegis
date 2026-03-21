#pragma once
#include <vector>
#include <cstddef>

namespace aegis {
namespace crypto {

// AEAD encrypt: returns true on success. On success `ciphertext` will contain
// the encrypted bytes and `tag` will contain the authentication tag.
bool encrypt(const std::vector<uint8_t>& key,
             const std::vector<uint8_t>& nonce,
             const std::vector<uint8_t>& plaintext,
             std::vector<uint8_t>& ciphertext,
             std::vector<uint8_t>& tag) noexcept;

// AEAD decrypt: returns true on success and populates `plaintext`.
bool decrypt(const std::vector<uint8_t>& key,
             const std::vector<uint8_t>& nonce,
             const std::vector<uint8_t>& ciphertext,
             const std::vector<uint8_t>& tag,
             std::vector<uint8_t>& plaintext) noexcept;

} // namespace crypto
} // namespace aegis
