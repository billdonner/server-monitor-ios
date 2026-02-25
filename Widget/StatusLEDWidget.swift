import WidgetKit
import SwiftUI

// MARK: - Status LED Widget

/// A simple red/yellow/green LED widget showing overall server health.
struct StatusLEDWidgetEntryView: View {
    var entry: ZerverMonitorEntry
    @Environment(\.widgetFamily) var family

    var body: some View {
        switch family {
        case .accessoryCircular:
            lockScreenView
        default:
            homeScreenView
        }
    }

    // MARK: Lock Screen — icon + colored circle

    private var lockScreenView: some View {
        ZStack {
            AccessoryWidgetBackground()
            Circle()
                .fill(overallColor)
                .frame(width: 20, height: 20)
        }
    }

    // MARK: Home Screen — dot + label

    private var homeScreenView: some View {
        VStack(spacing: 8) {
            Circle()
                .fill(overallColor)
                .frame(width: 32, height: 32)
                .shadow(color: overallColor.opacity(0.5), radius: 8)
            Text(overallLabel)
                .font(.caption2.bold())
                .foregroundStyle(.secondary)
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: Helpers

    private var overallColor: Color {
        if entry.error != nil { return .red }
        let servers = entry.servers
        if servers.isEmpty { return .gray }
        if servers.contains(where: { $0.error != nil }) { return .red }
        if servers.contains(where: { $0.isWarned }) { return .yellow }
        return .green
    }

    private var overallLabel: String {
        if entry.error != nil { return "Offline" }
        let servers = entry.servers
        if servers.isEmpty { return "No Data" }
        let errored = servers.filter { $0.error != nil }.count
        if errored > 0 { return "\(errored) Down" }
        let warned = servers.filter { $0.isWarned }.count
        if warned > 0 { return "\(warned) Warned" }
        return "All OK"
    }
}

struct StatusLEDWidget: Widget {
    let kind = "StatusLEDWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: ZerverMonitorProvider()) { entry in
            StatusLEDWidgetEntryView(entry: entry)
                .containerBackground(.fill.tertiary, for: .widget)
        }
        .configurationDisplayName("Status LED")
        .description("Simple red/yellow/green health indicator.")
        .supportedFamilies([.accessoryCircular, .systemSmall])
    }
}
