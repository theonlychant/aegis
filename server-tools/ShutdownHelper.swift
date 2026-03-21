#!/usr/bin/env swift
import Foundation

// ShutdownHelper.swift
// Graceful shutdown helper for server-side use. Provides functions to:
// - stop named system services (systemctl) when available
// - signal processes by PID or name (POSIX)
// - flush filesystem buffers
// - send an optional admin notification webhook
//
// This helper focuses on graceful service termination and preservation of
// logs and data. It does NOT perform data destruction or hiding.

struct ShutdownHelper {
    static func stopServices(_ names: [String], timeoutSeconds: Int = 30) {
        for name in names {
            if runCommand(launchPath: "/usr/bin/env", args: ["systemctl", "is-active", "--quiet", name]) == 0 {
                print("Stopping service: \(name)")
                _ = runCommand(launchPath: "/usr/bin/env", args: ["systemctl", "stop", name])
            } else {
                print("Service not active or systemctl not present: \(name)")
            }
        }
        // Wait a bit for processes to exit
        sleep(UInt32(timeoutSeconds))
    }

    static func signalProcesses(byName name: String, signal: Int32 = SIGTERM) {
        // Use pgrep (if available) to find processes
        let pgrepResult = runCommand(launchPath: "/usr/bin/env", args: ["pgrep", "-f", name])
        if pgrepResult == 0 {
            // collect pids
            let task = Process()
            task.executableURL = URL(fileURLWithPath: "/usr/bin/env")
            task.arguments = ["pgrep", "-f", name]
            let pipe = Pipe()
            task.standardOutput = pipe
            do {
                try task.run()
                task.waitUntilExit()
                let data = pipe.fileHandleForReading.readDataToEndOfFile()
                if let out = String(data: data, encoding: .utf8) {
                    let lines = out.split(separator: "\n")
                    for l in lines {
                        if let pid = Int32(l.trimmingCharacters(in: .whitespaces)) {
                            print("Signaling PID \(pid) with signal \(signal)")
                            kill(pid, signal)
                        }
                    }
                }
            } catch {
                print("pgrep failed: \(error)")
            }
        } else {
            print("pgrep did not find processes for: \(name) or pgrep missing")
        }
    }

    static func flushFilesystems() {
        print("Flushing filesystem buffers (sync)")
        _ = runCommand(launchPath: "/usr/bin/env", args: ["sync"]) // best-effort
    }

    static func notifyAdmin(webhookURL: String, message: String) {
        guard let url = URL(string: webhookURL) else { print("Invalid webhook URL"); return }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        let payload = ["text": message]
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: payload, options: [])
            let semaphore = DispatchSemaphore(value: 0)
            let task = URLSession.shared.dataTask(with: request) { _, response, error in
                if let e = error { print("Notify error: \(e)") }
                else if let http = response as? HTTPURLResponse { print("Notify response: \(http.statusCode)") }
                semaphore.signal()
            }
            task.resume()
            semaphore.wait(timeout: .now() + 5)
        } catch {
            print("Failed to build notification payload: \(error)")
        }
    }

    @discardableResult
    static func runCommand(launchPath: String, args: [String]) -> Int32 {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: launchPath)
        process.arguments = args
        let pipe = Pipe()
        process.standardOutput = pipe
        process.standardError = pipe
        do {
            try process.run()
            process.waitUntilExit()
            return process.terminationStatus
        } catch {
            print("Command failed: \(launchPath) \(args) -> \(error)")
            return -1
        }
    }
}

// Simple CLI usage: ShutdownHelper.swift stop <service1> <service2> ...
let argv = CommandLine.arguments
if argv.count >= 2 {
    let cmd = argv[1]
    if cmd == "stop" && argv.count >= 3 {
        let services = Array(argv.dropFirst(2))
        ShutdownHelper.stopServices(services)
        ShutdownHelper.flushFilesystems()
        if let webhook = ProcessInfo.processInfo.environment["ADMIN_WEBHOOK"] {
            ShutdownHelper.notifyAdmin(webhookURL: webhook, message: "Services stopped: \(services)")
        }
    } else if cmd == "signal" && argv.count >= 3 {
        let name = argv[2]
        ShutdownHelper.signalProcesses(byName: name)
        ShutdownHelper.flushFilesystems()
    } else {
        print("Usage: ShutdownHelper.swift stop <service...> | signal <process-name>")
    }
} else {
    print("Usage: ShutdownHelper.swift stop <service...> | signal <process-name>")
}
