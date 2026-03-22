import Foundation
import Security

struct KeychainHelper {
    static func store(key: Data, account: String, service: String) -> Bool {
        let query: [String: Any] = [kSecClass as String: kSecClassKey,
                                    kSecAttrApplicationTag as String: account,
                                    kSecAttrService as String: service,
                                    kSecValueData as String: key]
        SecItemDelete(query as CFDictionary)
        let status = SecItemAdd(query as CFDictionary, nil)
        return status == errSecSuccess
    }

    static func retrieve(account: String, service: String) -> Data? {
        let query: [String: Any] = [kSecClass as String: kSecClassKey,
                                    kSecAttrApplicationTag as String: account,
                                    kSecAttrService as String: service,
                                    kSecReturnData as String: kCFBooleanTrue!,
                                    kSecMatchLimit as String: kSecMatchLimitOne]
        var item: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &item)
        guard status == errSecSuccess, let data = item as? Data else { return nil }
        return data
    }
}
