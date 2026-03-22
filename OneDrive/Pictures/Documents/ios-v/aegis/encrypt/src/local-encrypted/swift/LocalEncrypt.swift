import Foundation

@objcMembers
public class LocalEncryptSwift: NSObject {
    private let impl = LocalEncrypt()

    public override init() { super.init() }

    public func encrypt(data: Data, key: Data, nonce: Data) throws -> Data {
        var error: NSError?
        guard let result = impl.encryptData(data, key: key, nonce: nonce, error: &error) else {
            throw error ?? NSError(domain: "AegisEncrypt", code: -1, userInfo: nil)
        }
        return result as Data
    }

    public func decrypt(ciphertext: Data, tag: Data, key: Data, nonce: Data) throws -> Data {
        var error: NSError?
        guard let result = impl.decryptData(ciphertext, tag: tag, key: key, nonce: nonce, error: &error) else {
            throw error ?? NSError(domain: "AegisEncrypt", code: -1, userInfo: nil)
        }
        return result as Data
    }
}
