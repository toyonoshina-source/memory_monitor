//
//  MenuBarContentView.swift
//  memory_monitor
//
//  Created by 石田達矢 on 2026/08/16.
//

import SwiftUI
#if os(macOS)

struct MenuBarContentView: View {
    @ObservedObject var monitor: MemoryMonitor

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("WindowServer メモリ監視")
                .font(.headline)

            Text(monitor.menuBarTitle)
                .font(.system(.title2, design: .rounded))
                .bold()

            if let lastUpdated = monitor.lastUpdated {
                Text("更新: \(lastUpdated.formatted(date: .omitted, time: .standard))")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Divider()

            Button("今すぐ更新") {
                monitor.refresh()
            }

            Button("終了") {
                NSApp.terminate(nil)
            }
        }
        .padding(12)
        .frame(width: 220)
    }
}
#endif
