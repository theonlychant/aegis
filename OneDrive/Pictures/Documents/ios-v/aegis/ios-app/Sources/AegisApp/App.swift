import SwiftUI
import os

@main
struct AegisApp: App {
    init() {
        // Kick off rulepack fetch on app start
        let server = URL(string: "https://127.0.0.1:8443")!
        // Replace with actual base64 DER server public key in production
        let serverPubB64 = ""
        RuleManager.fetchAndApplyEncrypted(from: server, serverPubKeyDERBase64: serverPubB64)
        os_log("AegisApp: triggered rulepack fetch", type: .info)
    }

    var body: some Scene {
        WindowGroup {
            ZStack {
                ContentView()
                SecurityAlertView()
            }
        }
    }
}

struct ContentView: View {
    var body: some View {
        VStack(spacing: 16) {
            Text("Aegis")
                .font(.largeTitle)
                .bold()
            Text("iPhone security platform — skeleton app")
                .foregroundColor(.secondary)
        }
        .padding()
    }
}
