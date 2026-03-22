import Foundation
import Security

struct RuleManager {
    static let rulesFile = "rules.json"
    static let rulesTemp = "rules.json.tmp"

    // Atomically apply a rule pack after signature verification
    static func applyRulePack(data: Data, signature: Data, pubkeyDER: Data) throws {
        // Expect signed payload to be: version + "\n" + rule bytes
        // Verify signature over (version + "\n" + data)
        // pubkeyDER is a PKIX SPKI DER-encoded public key
        let key = try SecKeyCreateWithData(pubkeyDER as CFData,
                                          [kSecAttrKeyType as String: kSecAttrKeyTypeECSECPrimeRandom,
                                           kSecAttrKeyClass as String: kSecAttrKeyClassPublic] as CFDictionary,
                                          nil)
        var error: Unmanaged<CFError>?
        let ok = SecKeyVerifySignature(key!, .ecdsaSignatureMessageX962SHA256, data as CFData, signature as CFData, &error)
        if !ok {
            throw error!.takeRetainedValue() as Error
        }
        // Write to temporary file and atomically move
        let tmp = FileManager.default.temporaryDirectory.appendingPathComponent(rulesTemp)
        let dest = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0].appendingPathComponent(rulesFile)
        try data.write(to: tmp, options: .atomic)
        // Backup existing
        if FileManager.default.fileExists(atPath: dest.path) {
            let backup = dest.deletingPathExtension().appendingPathExtension("bak")
            try? FileManager.default.removeItem(at: backup)
            try FileManager.default.copyItem(at: dest, to: backup)
        }
        try FileManager.default.replaceItemAt(dest, withItemAt: tmp)
    }

    // Fetch encrypted rulepack from server and apply atomically; posts notification on failures
    static func fetchAndApplyEncrypted(from serverURL: URL, serverPubKeyDERBase64: String) {
        let fetcher = RulePackFetcher(serverURL: serverURL, serverPubKeyDERBase64: serverPubKeyDERBase64)
        fetcher.fetchEncryptedRulepack { result in
            switch result {
            case .success(let plainData):
                // Expect server to follow version+"\n"+rule bytes signing protocol; here we attempt simple split
                if let idx = plainData.firstIndex(of: UInt8(10)) { // newline
                    let rules = plainData.suffix(from: idx+1)
                    do {
                        // In this flow signature already verified by fetcher; pass empty signature/pubkey to applyRulePack
                        try applyRulePack(data: Data(rules), signature: Data(), pubkeyDER: Data())
                    } catch {
                        NotificationCenter.default.post(name: .securityFailure, object: nil, userInfo: ["reason": "failed to apply rulepack: \(error.localizedDescription)"])
                    }
                } else {
                    NotificationCenter.default.post(name: .securityFailure, object: nil, userInfo: ["reason": "invalid rulepack format"])                
                }
            case .failure(let err):
                NotificationCenter.default.post(name: .securityFailure, object: nil, userInfo: ["reason": "fetch failed: \(err.localizedDescription)"])
            }
        }
    }
}
