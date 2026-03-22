#!/usr/bin/env swift
import Foundation

// BackupManager.swift
// Safe backup helper for server-side use. Creates a compressed archive of
// specified paths, encrypts it using GPG symmetric encryption (AES256),
// and optionally uploads the encrypted archive to a configured endpoint.
//
// Security notes:
// - This script DOES NOT delete or hide any data. It only creates an
//   encrypted backup archive. Deletion or data-hiding operations are
//   intentionally omitted for safety and auditability.
// - Configure a secure place to store the passphrase or use GPG agent.
// - The upload endpoint (if used) must be an authenticated secure storage.

struct BackupManager {
    enum BackupError: Error {
        case tarFailed
        case encryptionFailed
        case uploadFailed
    }

    static func run(paths: [String], archiveName: String = "backup", outputDir: String = ".") throws {
        let fileManager = FileManager.default
        try fileManager.createDirectory(atPath: outputDir, withIntermediateDirectories: true)

        let archivePath = (outputDir as NSString).appendingPathComponent("\(archiveName).tar.gz")
        let encryptedPath = archivePath + ".gpg"

        // 1) Create tar.gz archive
        var tarArgs = ["-czf", archivePath]
        tarArgs.append(contentsOf: paths)
        let tar = Process()
        tar.executableURL = URL(fileURLWithPath: "/usr/bin/env")
        tar.arguments = ["tar"] + tarArgs

        print("Creating archive: \(archivePath)")
        try runProcess(tar)

        // 2) Encrypt archive with GPG symmetric AES256
        guard let gpgPass = ProcessInfo.processInfo.environment["BACKUP_PASSPHRASE"], !gpgPass.isEmpty else {
            print("BACKUP_PASSPHRASE not set in environment. Skipping encryption (not recommended).")
            throw BackupError.encryptionFailed
        }

        let gpg = Process()
        gpg.executableURL = URL(fileURLWithPath: "/usr/bin/env")
        // Use --batch and --passphrase-fd 0 to pass the passphrase via stdin
        gpg.arguments = ["gpg", "--symmetric", "--cipher-algo", "AES256", "--batch", "--passphrase-fd", "0", "-o", encryptedPath, archivePath]

        print("Encrypting archive to: \(encryptedPath)")
        try runProcess(gpg, stdinString: gpgPass + "\n")

        // 3) Optional upload
        if let uploadURL = ProcessInfo.processInfo.environment["BACKUP_UPLOAD_URL"], !uploadURL.isEmpty {
            print("Uploading encrypted archive to: \(uploadURL)")
            let apiToken = ProcessInfo.processInfo.environment["BACKUP_API_TOKEN"]
            let url = URL(string: uploadURL)!
            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            if let token = apiToken { request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization") }

            let semaphore = DispatchSemaphore(value: 0)
            var uploadError: Error?

            let task = URLSession.shared.uploadTask(with: request, fromFile: URL(fileURLWithPath: encryptedPath)) { data, response, error in
                if let e = error { uploadError = e }
                else if let http = response as? HTTPURLResponse, http.statusCode >= 400 {
                    uploadError = BackupError.uploadFailed
                }
                semaphore.signal()
            }
            task.resume()
            semaphore.wait()
            if let e = uploadError { print("Upload failed: \(e)"); throw BackupError.uploadFailed }
            print("Upload complete")
        } else {
            print("No BACKUP_UPLOAD_URL set — encrypted archive written to: \(encryptedPath)")
        }

        print("Backup finished successfully")
    }

    private static func runProcess(_ process: Process, stdinString: String? = nil) throws {
        let pipe = Pipe()
        process.standardOutput = pipe
        process.standardError = pipe
        if let input = stdinString {
            let inPipe = Pipe()
            inPipe.fileHandleForWriting.write(input.data(using: .utf8)!)
            inPipe.fileHandleForWriting.closeFile()
            process.standardInput = inPipe
        }
        try process.run()
        process.waitUntilExit()
        if process.terminationStatus != 0 {
            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            if let output = String(data: data, encoding: .utf8) { print(output) }
            throw BackupError.tarFailed
        }
    }
}

// Simple CLI
let args = CommandLine.arguments
if args.count < 2 {
    print("Usage: BackupManager.swift <path1> [path2 ...] (set BACKUP_PASSPHRASE and optional BACKUP_UPLOAD_URL)")
    exit(1)
}
let toBackup = Array(args.dropFirst())

do {
    try BackupManager.run(paths: toBackup)
} catch {
    print("Backup failed: \(error)")
    exit(2)
}
