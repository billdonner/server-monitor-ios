import WidgetKit
import SwiftUI

// MARK: - Timeline Entry

struct WatchStatusEntry: TimelineEntry {
    let date: Date
    let servers: [ServerSnapshot]
    let error: String?

    static let placeholder = WatchStatusEntry(
        date: .now,
        servers: [
            ServerSnapshot(name: "Server 1", url: "", pollEvery: 15, lastUpdated: nil, metrics: [], error: nil, hadError: nil),
            ServerSnapshot(name: "Server 2", url: "", pollEvery: 10, lastUpdated: nil, metrics: [], error: nil, hadError: nil),
        ],
        error: nil
    )

    var overallColor: Color {
        if error != nil { return .red }
        if servers.isEmpty { return .gray }
        if servers.contains(where: { $0.error != nil }) { return .red }
        if servers.contains(where: { $0.isWarned }) { return .yellow }
        return .green
    }

    var overallLabel: String {
        if error != nil { return "Offline" }
        if servers.isEmpty { return "No Data" }
        let errored = servers.filter { $0.error != nil }.count
        if errored > 0 { return "\(errored) Down" }
        let warned = servers.filter { $0.isWarned }.count
        if warned > 0 { return "\(warned) Warned" }
        return "All OK"
    }
}

// MARK: - Timeline Provider

struct WatchStatusProvider: TimelineProvider {
    func placeholder(in context: Context) -> WatchStatusEntry {
        .placeholder
    }

    func getSnapshot(in context: Context, completion: @escaping (WatchStatusEntry) -> Void) {
        if context.isPreview {
            completion(.placeholder)
            return
        }
        Task {
            let entry = await fetchEntry()
            completion(entry)
        }
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<WatchStatusEntry>) -> Void) {
        Task {
            let entry = await fetchEntry()
            let nextUpdate = Calendar.current.date(byAdding: .minute, value: 15, to: entry.date)!
            let timeline = Timeline(entries: [entry], policy: .after(nextUpdate))
            completion(timeline)
        }
    }

    private func fetchEntry() async -> WatchStatusEntry {
        do {
            let response = try await StatusService.shared.fetchStatus()
            return WatchStatusEntry(date: .now, servers: response.servers, error: nil)
        } catch {
            return WatchStatusEntry(date: .now, servers: [], error: error.localizedDescription)
        }
    }
}

// MARK: - Circular Complication (colored dot)

struct CircularComplicationView: View {
    var entry: WatchStatusEntry

    var body: some View {
        ZStack {
            AccessoryWidgetBackground()
            Circle()
                .fill(entry.overallColor)
                .frame(width: 20, height: 20)
        }
    }
}

// MARK: - Corner Complication (colored dot + label)

struct CornerComplicationView: View {
    var entry: WatchStatusEntry

    var body: some View {
        ZStack {
            AccessoryWidgetBackground()
            Image(systemName: "server.rack")
                .font(.title3)
                .widgetLabel {
                    Text(entry.overallLabel)
                }
        }
        .foregroundStyle(entry.overallColor)
    }
}

// MARK: - Inline Complication (text)

struct InlineComplicationView: View {
    var entry: WatchStatusEntry

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: "server.rack")
            Text(entry.overallLabel)
        }
    }
}

// MARK: - Widget Configuration

struct WatchStatusLEDWidget: Widget {
    let kind = "WatchStatusLED"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: WatchStatusProvider()) { entry in
            CircularComplicationView(entry: entry)
                .containerBackground(.fill.tertiary, for: .widget)
        }
        .configurationDisplayName("Status LED")
        .description("Red, yellow, or green server health indicator.")
        .supportedFamilies([.accessoryCircular])
    }
}

struct WatchStatusCornerWidget: Widget {
    let kind = "WatchStatusCorner"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: WatchStatusProvider()) { entry in
            CornerComplicationView(entry: entry)
                .containerBackground(.fill.tertiary, for: .widget)
        }
        .configurationDisplayName("Server Status")
        .description("Server health in the corner of your watch face.")
        .supportedFamilies([.accessoryCorner])
    }
}

struct WatchStatusInlineWidget: Widget {
    let kind = "WatchStatusInline"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: WatchStatusProvider()) { entry in
            InlineComplicationView(entry: entry)
                .containerBackground(.fill.tertiary, for: .widget)
        }
        .configurationDisplayName("Server Inline")
        .description("Server health as inline text on your watch face.")
        .supportedFamilies([.accessoryInline])
    }
}

@main
struct WatchComplicationBundle: WidgetBundle {
    var body: some Widget {
        WatchStatusLEDWidget()
        WatchStatusCornerWidget()
        WatchStatusInlineWidget()
    }
}
