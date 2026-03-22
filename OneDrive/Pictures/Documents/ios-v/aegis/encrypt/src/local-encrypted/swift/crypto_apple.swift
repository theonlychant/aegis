import Foundation
import CryptoKit
import Security

// Keychain helpers
fileprivate func keychainStore(keyLabel: String, keyData: Data) -> Bool {
    let query: [String: Any] = [kSecClass as String: kSecClassGenericPassword,
                                kSecAttrAccount as String: keyLabel,
                                kSecValueData as String: keyData]
    SecItemDelete(query as CFDictionary)
    let status = SecItemAdd(query as CFDictionary, nil)
    return status == errSecSuccess
}

fileprivate func keychainRetrieve(keyLabel: String) -> Data? {
    let query: [String: Any] = [kSecClass as String: kSecClassGenericPassword,
                                kSecAttrAccount as String: keyLabel,
                                kSecReturnData as String: true,
                                kSecMatchLimit as String: kSecMatchLimitOne]
    var item: CFTypeRef?
    let status = SecItemCopyMatching(query as CFDictionary, &item)
    if status == errSecSuccess, let data = item as? Data { return data }
    return nil
}

// C-callable AES-GCM using CryptoKit. Signatures mirror the C bridge.
@_cdecl("aegis_encrypt_apple")
public func aegis_encrypt_apple(_ inPtr: UnsafePointer<UInt8>?, _ inLen: Int,
                                _ outPtr: UnsafeMutablePointer<UInt8>?, _ outLenPtr: UnsafeMutablePointer<Int>?,
                                _ tagPtr: UnsafeMutablePointer<UInt8>?, _ tagLenPtr: UnsafeMutablePointer<Int>?,
                                _ keyPtr: UnsafePointer<UInt8>?, _ keyLen: Int,
                                _ noncePtr: UnsafePointer<UInt8>?, _ nonceLen: Int) -> Int32 {
    guard let inPtr = inPtr, let outLenPtr = outLenPtr, let tagLenPtr = tagLenPtr, let keyPtr = keyPtr, let noncePtr = noncePtr else { return -1 }
    let plaintext = Data(bytes: inPtr, count: inLen)
    let keyData = Data(bytes: keyPtr, count: keyLen)
    let nonceData = Data(bytes: noncePtr, count: nonceLen)

    if outPtr == nil {
        // query required sizes
        // AES.GCM tag is 16 bytes
        outLenPtr.pointee = plaintext.count
        tagLenPtr.pointee = 16
        return 0
    }

    do {
        let symmetricKey = SymmetricKey(data: keyData)
        let sealed = try AES.GCM.seal(plaintext, using: symmetricKey, nonce: AES.GCM.Nonce(data: nonceData))
        let ct = sealed.ciphertext
        let tag = sealed.tag
        if outLenPtr.pointee < ct.count || tagLenPtr.pointee < tag.count { return -3 }
        ct.withUnsafeBytes { (ctBuf: UnsafeRawBufferPointer) in
            memcpy(outPtr, ctBuf.baseAddress!, ct.count)
        }
        tag.withUnsafeBytes { (tagBuf: UnsafeRawBufferPointer) in
            memcpy(tagPtr, tagBuf.baseAddress!, tag.count)
        }
        outLenPtr.pointee = ct.count
        tagLenPtr.pointee = tag.count
        return 0
    } catch {
        return -2
    }
}

@_cdecl("aegis_decrypt_apple")
public func aegis_decrypt_apple(_ inPtr: UnsafePointer<UInt8>?, _ inLen: Int,
                                _ tagPtr: UnsafePointer<UInt8>?, _ tagLen: Int,
                                _ outPtr: UnsafeMutablePointer<UInt8>?, _ outLenPtr: UnsafeMutablePointer<Int>?,
                                _ keyPtr: UnsafePointer<UInt8>?, _ keyLen: Int,
                                _ noncePtr: UnsafePointer<UInt8>?, _ nonceLen: Int) -> Int32 {
    guard let inPtr = inPtr, let outLenPtr = outLenPtr, let keyPtr = keyPtr, let noncePtr = noncePtr, let tagPtr = tagPtr else { return -1 }
    let ct = Data(bytes: inPtr, count: inLen)
    let tag = Data(bytes: tagPtr, count: tagLen)
    let keyData = Data(bytes: keyPtr, count: keyLen)
    let nonceData = Data(bytes: noncePtr, count: nonceLen)

    if outPtr == nil {
        outLenPtr.pointee = inLen
        return 0
    }

    do {
        let symmetricKey = SymmetricKey(data: keyData)
        let combined = try AES.GCM.SealedBox(nonce: AES.GCM.Nonce(data: nonceData), ciphertext: ct, tag: tag)
        let pt = try AES.GCM.open(combined, using: symmetricKey)
        if outLenPtr.pointee < pt.count { return -3 }
        pt.withUnsafeBytes { (ptBuf: UnsafeRawBufferPointer) in
            memcpy(outPtr, ptBuf.baseAddress!, pt.count)
        }
        outLenPtr.pointee = pt.count
        return 0
    } catch {
        return -2
    }
}
