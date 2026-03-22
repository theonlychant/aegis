import Foundation
import CryptoKit
import LocalAuthentication

struct SecureEnclaveHelper {
    static func generateKey(label: String) throws -> SecureEnclave.P256.Signing.PrivateKey {
        let access = SecAccessControlCreateWithFlags(nil,
                                                     kSecAttrAccessibleWhenUnlockedThisDeviceOnly,
                                                     .privateKeyUsage,
                                                     nil)!
        let attributes: [String: Any] = [kSecAttrKeyType as String: kSecAttrKeyTypeECSECPrimeRandom,
                                         kSecAttrKeySizeInBits as String: 256,
                                         kSecAttrTokenID as String: kSecAttrTokenIDSecureEnclave,
                                         kSecPrivateKeyAttrs as String: [kSecAttrIsPermanent as String: true,
                                                                         kSecAttrApplicationTag as String: label,
                                                                         kSecAttrAccessControl as String: access]]
        var error: Unmanaged<CFError>?
        guard let secKey = SecKeyCreateRandomKey(attributes as CFDictionary, &error) else {
            throw error!.takeRetainedValue() as Error
        }
        return try SecureEnclave.P256.Signing.PrivateKey(secKey: secKey)
    }

    static func sign(message: Data, label: String) throws -> Data {
        // Find key by application tag
        let query: [String: Any] = [kSecClass as String: kSecClassKey,
                                    kSecAttrApplicationTag as String: label,
                                    kSecReturnRef as String: true]
        var item: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &item)
        guard status == errSecSuccess, let secKey = item as? SecKey else {
            throw NSError(domain: "SecureEnclaveHelper", code: -1, userInfo: [NSLocalizedDescriptionKey: "key not found"])
        }
        var error: Unmanaged<CFError>?
        guard let sig = SecKeyCreateSignature(secKey,
                                              .ecdsaSignatureMessageX962SHA256,
                                              message as CFData,
                                              &error) as Data? else {
            throw error!.takeRetainedValue() as Error
        }
        return sig
    }
}
