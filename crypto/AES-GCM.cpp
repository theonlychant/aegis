// AES-GCM.cpp
// This is a backup of the AES-GCM encryption/decryption code using Crypto++ library.
// author: Devco22
// THIS is a backup file not needed right now will edit later(chant)
#include <cryptopp/gcm.h>
#include <cryptopp/aes.h>
#include <cryptopp/filters.h>

using namespace CryptoPP;

std::string encrypt(
    const std::string& plaintext,
    const SecByteBlock& key,
    const byte* iv, size_t iv_len)
{
    GCM<AES>::Encryption enc;
    enc.SetKeyWithIV(key, key.size(), iv, iv_len);

    std::string ciphertext;
    AuthenticatedEncryptionFilter ef(enc,
        new StringSink(ciphertext)
    );

    ef.Put(reinterpret_cast<const byte*>(plaintext.data()), plaintext.size());
    ef.MessageEnd();

    return ciphertext;
}
