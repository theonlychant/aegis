import Foundation
import Security
import CryptoKit

public enum SecureEnclaveError: Error {
    case creationFailed
    case keyNotFound
    case exportFailed
    case keyExchangeFailed
    case decryptionFailed
}

public struct SecureEnclaveKeyManager {
    // Create or fetch an EC P-256 private key stored in the Secure Enclave with a given tag.
    public static func createOrGetKey(tag: String) throws -> SecKey {
        let tagData = tag.data(using: .utf8)! as CFData
        // Search
        var query: [String: Any] = [kSecClass as String: kSecClassKey,
                                    kSecAttrApplicationTag as String: tagData,
                                    kSecAttrKeyType as String: kSecAttrKeyTypeECSECPrimeRandom,
                                    kSecReturnRef as String: true]
        var item: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &item)
        if status == errSecSuccess, let key = item as! SecKey? {
            return key
        }

        // Create
        var attributes: [String: Any] = [:]
        attributes[kSecAttrKeyType as String] = kSecAttrKeyTypeECSECPrimeRandom
        attributes[kSecAttrKeySizeInBits as String] = 256
        attributes[kSecAttrTokenID as String] = kSecAttrTokenIDSecureEnclave
        var privateAttrs: [String: Any] = [:]
        privateAttrs[kSecAttrIsPermanent as String] = true
        privateAttrs[kSecAttrApplicationTag as String] = tagData
        attributes[kSecPrivateKeyAttrs as String] = privateAttrs

        var error: Unmanaged<CFError>?
        guard let key = SecKeyCreateRandomKey(attributes as CFDictionary, &error) else {
            throw SecureEnclaveError.creationFailed
        }
        return key
    }

    // Return the public key raw (uncompressed) bytes (04||X||Y)
    public static func publicKeyRaw(from privateKey: SecKey) throws -> Data {
        guard let pub = SecKeyCopyPublicKey(privateKey) else { throw SecureEnclaveError.keyNotFound }
        var error: Unmanaged<CFError>?
        guard let data = SecKeyCopyExternalRepresentation(pub, &error) as Data? else {
            throw SecureEnclaveError.exportFailed
        }
        return data
    }

    // Derive ECDH shared secret with peer's uncompressed public key bytes
    public static func deriveSharedSecret(privateKey: SecKey, peerPublicRaw: Data) throws -> Data {
        // Create SecKey for peer pub
        let attrs: [String: Any] = [kSecAttrKeyType as String: kSecAttrKeyTypeECSECPrimeRandom,
                                    kSecAttrKeyClass as String: kSecAttrKeyClassPublic,
                                    kSecAttrKeySizeInBits as String: 256]
        var error: Unmanaged<CFError>?
        guard let peerKey = SecKeyCreateWithData(peerPublicRaw as CFData, attrs as CFDictionary, &error) else {
            throw SecureEnclaveError.keyNotFound
        }
        // ECDH key exchange
        let algorithm = SecKeyAlgorithm.ecdhKeyExchangeStandard
        guard SecKeyIsAlgorithmSupported(privateKey, .keyExchange, algorithm) else {
            throw SecureEnclaveError.keyExchangeFailed
        }
        var cfErr: Unmanaged<CFError>?
        guard let shared = SecKeyCopyKeyExchangeResult(privateKey, algorithm, peerKey, nil, &cfErr) as Data? else {
            throw SecureEnclaveError.keyExchangeFailed
        }
        // Derive symmetric key material via SHA256
        let hashed = SHA256.hash(data: shared)
        return Data(hashed)
    }

    // Decrypt AES-GCM ciphertext given symmetric key bytes (32), nonce, and ciphertext
    public static func decryptAESGCM(keyBytes: Data, nonce: Data, ciphertext: Data) throws -> Data {
        let sym = SymmetricKey(data: keyBytes)
        // Go's GCM.Seal returns ciphertext||tag. CryptoKit expects a combined representation of nonce||ciphertext||tag.
        let combined = nonce + ciphertext
        let sealedBox = try AES.GCM.SealedBox(combined: combined)
        return try AES.GCM.open(sealedBox, using: sym)
    }
}
