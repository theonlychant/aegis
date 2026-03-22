import Foundation
import CryptoKit

public struct EncryptedRuleResponse: Codable {
    public let version: String
    public let kid: String
    public let ephemeral_pub: String
    public let nonce: String
    public let ciphertext: String
    public let signature: String
}

public class RulePackFetcher {
    let serverURL: URL
    let serverPubKeyDERBase64: String // signer verification key
    let keyTag = "com.aegis.devicekey.v1"

    public init(serverURL: URL, serverPubKeyDERBase64: String) {
        self.serverURL = serverURL
        self.serverPubKeyDERBase64 = serverPubKeyDERBase64
    }

    public func fetchEncryptedRulepack(completion: @escaping (Result<Data, Error>) -> Void) {
        DispatchQueue.global().async {
            do {
                // Ensure device key
                let priv = try SecureEnclaveKeyManager.createOrGetKey(tag: self.keyTag)
                let pubRaw = try SecureEnclaveKeyManager.publicKeyRaw(from: priv)
                let pubB64 = Data(pubRaw).base64EncodedString()

                // Build request
                var req = URLRequest(url: self.serverURL.appendingPathComponent("/rules/encrypted"))
                req.httpMethod = "POST"
                req.addValue("application/json", forHTTPHeaderField: "Content-Type")
                let body = ["pubkey": pubB64]
                req.httpBody = try JSONSerialization.data(withJSONObject: body, options: [])

                let (data, resp) = try URLSession.shared.syncRequest(with: req)
                guard let http = resp as? HTTPURLResponse, http.statusCode == 200 else {
                    throw NSError(domain: "RulePackFetcher", code: 1, userInfo: [NSLocalizedDescriptionKey: "bad response"]) 
                }
                let enc = try JSONDecoder().decode(EncryptedRuleResponse.self, from: data)

                // Decode fields
                guard let ephPub = Data(base64Encoded: enc.ephemeral_pub),
                      let nonce = Data(base64Encoded: enc.nonce),
                      let ciphertext = Data(base64Encoded: enc.ciphertext) else {
                    throw NSError(domain: "RulePackFetcher", code: 2, userInfo: [NSLocalizedDescriptionKey: "invalid encoding"])
                }

                // Derive shared secret
                let shared = try SecureEnclaveKeyManager.deriveSharedSecret(privateKey: priv, peerPublicRaw: ephPub)
                let key = SHA256.hash(data: shared)
                let keyBytes = Data(key)

                // Verify signature: payload = version + "\n" + ciphertext
                let payload = appendVersionAndBytes(version: enc.version, bytes: ciphertext)
                let ok = IntegrityChecker.verifyManifest(manifest: payload, signatureBase64: enc.signature, publicKeyDERBase64: self.serverPubKeyDERBase64)
                if !ok {
                    throw NSError(domain: "RulePackFetcher", code: 3, userInfo: [NSLocalizedDescriptionKey: "signature verification failed"])
                }

                // Decrypt
                let plain = try SecureEnclaveKeyManager.decryptAESGCM(keyBytes: keyBytes, nonce: nonce, ciphertext: ciphertext)
                completion(.success(plain))
            } catch {
                completion(.failure(error))
            }
        }
    }

    private func appendVersionAndBytes(version: String, bytes: Data) -> Data {
        var out = Data()
        out.append((version + "\n").data(using: .utf8)!)
        out.append(bytes)
        return out
    }
}

// Minimal synchronous URLSession helper for brevity
fileprivate extension URLSession {
    func syncRequest(with request: URLRequest) throws -> (Data, URLResponse) {
        var resultData: Data?
        var resultResp: URLResponse?
        var resultErr: Error?
        let sem = DispatchSemaphore(value: 0)
        let task = self.dataTask(with: request) { d, r, e in
            resultData = d
            resultResp = r
            resultErr = e
            sem.signal()
        }
        task.resume()
        sem.wait()
        if let e = resultErr { throw e }
        return (resultData ?? Data(), resultResp ?? URLResponse())
    }
}
