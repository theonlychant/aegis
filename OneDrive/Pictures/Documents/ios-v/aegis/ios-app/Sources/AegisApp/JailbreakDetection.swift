import Foundation

struct JailbreakDetection {
    static func isJailbroken() -> Bool {
        // Check for common jailbreak files
        let paths = ["/Applications/Cydia.app",
                     "/Library/MobileSubstrate/MobileSubstrate.dylib",
                     "/bin/sh",
                     "/usr/sbin/sshd",
                     "/etc/apt"]
        for p in paths {
            if FileManager.default.fileExists(atPath: p) {
                return true
            }
        }
        // Check if app can write outside container
        let testPath = "/private/jb_test_\(UUID().uuidString)"
        do {
            try "test".write(toFile: testPath, atomically: true, encoding: .utf8)
            // cleanup
            try FileManager.default.removeItem(atPath: testPath)
            return true
        } catch {
            // expected on non-jailbroken
        }
        // Check suspicious symlinks
        if FileManager.default.fileExists(atPath: "/Applications") {
            if let attrs = try? FileManager.default.attributesOfItem(atPath: "/Applications"),
               let fileType = attrs[.type] as? FileAttributeType, fileType == .typeSymbolicLink {
                return true
            }
        }
        return false
    }
}
