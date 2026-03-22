import Foundation
import CryptoKit

public struct IntegrityChecker {
    /// Verify a signed manifest using a DER-encoded P-256 public key and a DER ECDSA signature (both base64-encoded)
    /// - Parameters:
    ///   - manifest: raw manifest bytes (the data that was signed)
    ///   - signatureBase64: base64 DER-encoded ECDSA signature
    ///   - publicKeyDERBase64: base64 DER-encoded P-256 public key (X.509 / SubjectPublicKeyInfo or raw DER)
    /// - Returns: true if signature verifies
    public static func verifyManifest(manifest: Data, signatureBase64: String, publicKeyDERBase64: String) -> Bool {
        guard let sigData = Data(base64Encoded: signatureBase64),
              let pubKeyData = Data(base64Encoded: publicKeyDERBase64) else {
            return false
        }

        do {
            let pubKey = try P256.Signing.PublicKey(derRepresentation: pubKeyData)
            let signature = try P256.Signing.ECDSASignature(derRepresentation: sigData)
            return pubKey.isValidSignature(signature, for: manifest)
        } catch {
            return false
        }
    }
}
