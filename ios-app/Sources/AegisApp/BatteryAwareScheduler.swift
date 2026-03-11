import Foundation
import BackgroundTasks
import UIKit

final class BatteryAwareScheduler {
    static let shared = BatteryAwareScheduler()
    private init() {}

    func register() {
        if #available(iOS 13.0, *) {
            BGTaskScheduler.shared.register(forTaskWithIdentifier: "com.example.aegis.scan", using: nil) { task in
                self.handleScanTask(task: task as! BGProcessingTask)
            }
        }
    }

    func scheduleScan() {
        if #available(iOS 13.0, *) {
            let request = BGProcessingTaskRequest(identifier: "com.example.aegis.scan")
            // Require external power for heavy scanning unless user opted-in
            request.requiresExternalPower = false
            request.requiresNetworkConnectivity = false
            // Earliest begin date — schedule a conservative interval
            request.earliestBeginDate = Date(timeIntervalSinceNow: 60 * 60) // 1 hour
            do {
                try BGTaskScheduler.shared.submit(request)
            } catch {
                print("Failed to schedule background scan: \(error)")
            }
        }
    }

    private func handleScanTask(task: BGProcessingTask) {
        scheduleScan() // schedule next

        let queue = OperationQueue()
        queue.maxConcurrentOperationCount = 1

        task.expirationHandler = {
            queue.cancelAllOperations()
        }

        let op = BlockOperation {
            // Check battery and low power mode
            let lowPower = ProcessInfo.processInfo.isLowPowerModeEnabled
            UIDevice.current.isBatteryMonitoringEnabled = true
            let level = UIDevice.current.batteryLevel

            // Skip heavy scanning if low power or battery below threshold
            if lowPower || level >= 0 && level < 0.2 {
                print("Skipping heavy scan due to battery/low power: level=\(level) lowPower=\(lowPower)")
                return
            }

            // Perform scanning work: delegate to engine and local rule pack
            // Example placeholder: call into scanning API to run background scan
            performBackgroundScan()
        }

        queue.addOperation(op)

        op.completionBlock = {
            task.setTaskCompleted(success: !op.isCancelled)
        }
    }

    private func performBackgroundScan() {
        // Hook here to call scanning pipeline with lower-priority QoS
        print("Running background scan... (placeholder)")
    }
}
