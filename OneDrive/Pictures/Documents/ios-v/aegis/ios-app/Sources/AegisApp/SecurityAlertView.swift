import SwiftUI

public struct SecurityAlertView: View {
    @State private var showAlert: Bool = false
    @State private var message: String = ""

    public init() {}

    public var body: some View {
        Color.clear
            .onReceive(NotificationCenter.default.publisher(for: .securityFailure)) { notif in
                if let info = notif.userInfo as? [String: String], let reason = info["reason"] {
                    self.message = reason
                } else if let reason = notif.object as? String {
                    self.message = reason
                } else {
                    self.message = "Security warning: integrity check failed."
                }
                self.showAlert = true
            }
            .alert(isPresented: $showAlert) {
                Alert(title: Text("Security Warning"),
                      message: Text(message),
                      dismissButton: .default(Text("OK"), action: {
                          // Optionally post a notification that user acknowledged
                          NotificationCenter.default.post(name: Notification.Name("AegisSecurityAcknowledged"), object: nil)
                      }))
            }
    }
}
