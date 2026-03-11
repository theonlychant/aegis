import SwiftUI
import UniformTypeIdentifiers

// Bridge to the Rust FFI functions exposed via engine C header.
@_silgen_name("aegis_canonicalize_url")
func aegis_canonicalize_url(_ input: UnsafePointer<CChar>?) -> UnsafeMutablePointer<CChar>?

@_silgen_name("aegis_string_free")
func aegis_string_free(_ s: UnsafeMutablePointer<CChar>?)

struct DocumentScannerView: View {
    @State private var showingPicker = false
    @State private var lastVerdict: String = "None"

    var body: some View {
        VStack(spacing: 16) {
            Button("Import Document") { showingPicker = true }
            Text("Last verdict: \(lastVerdict)")
        }
        .fileImporter(isPresented: $showingPicker, allowedContentTypes: [UTType.data, UTType.pdf, UTType.plainText]) { result in
            switch result {
            case .success(let url):
                scanImportedFile(url: url)
            case .failure(let err):
                lastVerdict = "import failed: \(err.localizedDescription)"
            }
        }
        .padding()
    }

    func scanImportedFile(url: URL) {
        // Example: read first few bytes and run a quick rule (placeholder).
        do {
            let data = try Data(contentsOf: url)
            // Call into Rust FFI scan for a stronger check
            data.withUnsafeBytes { (ptr: UnsafeRawBufferPointer) in
                let p = ptr.bindMemory(to: UInt8.self).baseAddress
                let len = data.count
                if let p = p {
                    let res = aegis_scan_buffer(p, UInt(len))
                    lastVerdict = (res == 1) ? "malicious (engine)" : "clean"
                    return
                }
            }
            lastVerdict = "scan failed"
        } catch {
            lastVerdict = "scan error: \(error.localizedDescription)"
        }
    }
}

struct DocumentScannerView_Previews: PreviewProvider {
    static var previews: some View {
        DocumentScannerView()
    }
}
