//
//  MemoryMonitor.swift
//  memory_monitor
//
//  Created by 石田達矢 on 2026/08/16.
//

import Foundation
#if os(macOS)
import Combine
import UserNotifications

@MainActor
final class MemoryMonitor: ObservableObject {
    static let thresholdBytes: Int64 = 3 * 1024 * 1024 * 1024 // 3GB
    private let processName = "WindowServer"
    private let pollInterval: TimeInterval = 10

    @Published private(set) var currentBytes: Int64 = 0
    @Published private(set) var lastUpdated: Date?

    private var timer: Timer?
    // Notification fires once per breach; resets once usage drops back below the threshold.
    private var didNotifyForCurrentBreach = false

    var menuBarTitle: String {
        formatted(currentBytes)
    }

    init() {
        start()
    }

    func start() {
        refresh()
        timer = Timer.scheduledTimer(withTimeInterval: pollInterval, repeats: true) { _ in
            Task { @MainActor [weak self] in self?.refresh() }
        }
    }

    func refresh() {
        guard let pid = Self.pid(ofProcessNamed: processName),
              let rssBytes = Self.residentMemory(ofPID: pid) else {
            return
        }
        currentBytes = rssBytes
        lastUpdated = Date()

        if rssBytes > Self.thresholdBytes {
            if !didNotifyForCurrentBreach {
                didNotifyForCurrentBreach = true
                notifyThresholdExceeded(bytes: rssBytes)
            }
        } else {
            didNotifyForCurrentBreach = false
        }
    }

    private func notifyThresholdExceeded(bytes: Int64) {
        let content = UNMutableNotificationContent()
        content.title = "WindowServerのメモリ使用量が超過"
        content.body = "\(processName) が \(formatted(bytes)) を使用しています(しきい値: \(formatted(Self.thresholdBytes)))"
        content.sound = .default

        let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: nil)
        UNUserNotificationCenter.current().add(request)
    }

    private func formatted(_ bytes: Int64) -> String {
        ByteCountFormatter.string(fromByteCount: bytes, countStyle: .memory)
    }

    private static func pid(ofProcessNamed name: String) -> pid_t? {
        guard let output = run("/usr/bin/pgrep", ["-x", name]),
              let firstLine = output.split(separator: "\n").first,
              let pid = pid_t(firstLine) else {
            return nil
        }
        return pid
    }

    private static func residentMemory(ofPID pid: pid_t) -> Int64? {
        guard let output = run("/bin/ps", ["-o", "rss=", "-p", String(pid)]),
              let rssKilobytes = Int64(output.trimmingCharacters(in: .whitespaces)) else {
            return nil
        }
        return rssKilobytes * 1024
    }

    private static func run(_ launchPath: String, _ arguments: [String]) -> String? {
        let task = Process()
        task.executableURL = URL(fileURLWithPath: launchPath)
        task.arguments = arguments

        let outputPipe = Pipe()
        task.standardOutput = outputPipe
        task.standardError = Pipe()

        do {
            try task.run()
        } catch {
            return nil
        }
        task.waitUntilExit()

        let data = outputPipe.fileHandleForReading.readDataToEndOfFile()
        return String(data: data, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
#endif
