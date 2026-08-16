//
//  memory_monitorApp.swift
//  memory_monitor
//
//  Created by 石田達矢 on 2026/08/16.
//

import SwiftUI
#if os(macOS)
import AppKit
import UserNotifications
#endif

@main
struct memory_monitorApp: App {
#if os(macOS)
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
    @StateObject private var monitor = MemoryMonitor()

    var body: some Scene {
        MenuBarExtra(monitor.menuBarTitle, systemImage: "memorychip") {
            MenuBarContentView(monitor: monitor)
        }
        .menuBarExtraStyle(.window)
    }
#else
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
#endif
}

#if os(macOS)
final class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) { _, _ in }
    }
}
#endif
