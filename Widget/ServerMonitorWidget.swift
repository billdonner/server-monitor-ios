import WidgetKit
import SwiftUI

// MARK: - Timeline Entry

struct ServerMonitorEntry: TimelineEntry {
    let date: Date
    let servers: [ServerSnapshot]
    let error: String?

    static let placeholder = ServerMonitorEntry(
        date: .now,
        servers: [
            ServerSnapshot(name: "Server 1", url: "", pollEvery: 15, lastUpdated: nil, metrics: [], error: nil),
            ServerSnapshot(name: "Server 2", url: "", pollEvery: 10, lastUpdated: nil, metrics: [], error: nil),
        ],
        error: nil
    )
}

// MARK: - Timeline Provider

struct ServerMonitorProvider: TimelineProvider {
    func placeholder(in context: Context) -> ServerMonitorEntry {
        .placeholder
    }

    func getSnapshot(in context: Context, completion: @escaping (ServerMonitorEntry) -> Void) {
        if context.isPreview {
            completion(.placeholder)
            return
        }
        Task {
            let entry = await fetchEntry()
            completion(entry)
        }
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<ServerMonitorEntry>) -> Void) {
        Task {
            let entry = await fetchEntry()
            let nextUpdate = Calendar.current.date(byAdding: .minute, value: 15, to: entry.date)!
            let timeline = Timeline(entries: [entry], policy: .after(nextUpdate))
            completion(timeline)
        }
    }

    private func fetchEntry() async -> ServerMonitorEntry {
        do {
            let response = try await StatusService.shared.fetchStatus()
            return ServerMonitorEntry(date: .now, servers: response.servers, error: nil)
        } catch {
            return ServerMonitorEntry(date: .now, servers: [], error: error.localizedDescription)
        }
    }
}

// MARK: - Widget Views

struct ServerMonitorWidgetEntryView: View {
    var entry: ServerMonitorEntry
    @Environment(\.widgetFamily) var family

    var body: some View {
        switch family {
        case .systemSmall:
            smallView
        case .systemMedium:
            mediumView
        case .systemLarge:
            largeView
        default:
            smallView
        }
    }

    // MARK: Small — status dots + names

    private var smallView: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 4) {
                Image(systemName: "server.rack")
                    .font(.caption2)
                Text("Monitor")
                    .font(.caption2.bold())
            }
            .foregroundStyle(.secondary)

            if let error = entry.error {
                Text(error)
                    .font(.caption2)
                    .foregroundStyle(.red)
            } else {
                ForEach(entry.servers) { server in
                    HStack(spacing: 6) {
                        Circle()
                            .fill(dotColor(for: server))
                            .frame(width: 8, height: 8)
                        Text(server.name)
                            .font(.caption)
                            .lineLimit(1)
                    }
                }
            }

            Spacer(minLength: 0)
        }
        .padding(12)
    }

    // MARK: Medium — dots + names + summary

    private var mediumView: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Image(systemName: "server.rack")
                    .font(.caption)
                Text("Server Monitor")
                    .font(.caption.bold())
                Spacer()
                Text(summaryText)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }

            Divider()

            HStack(alignment: .top, spacing: 16) {
                ForEach(entry.servers) { server in
                    VStack(alignment: .leading, spacing: 4) {
                        HStack(spacing: 4) {
                            Circle()
                                .fill(dotColor(for: server))
                                .frame(width: 8, height: 8)
                            Text(server.name)
                                .font(.caption2.bold())
                                .lineLimit(1)
                        }
                        if let error = server.error {
                            Text(error)
                                .font(.system(size: 9))
                                .foregroundStyle(.red)
                                .lineLimit(2)
                        } else if server.metrics.isEmpty {
                            Text("waiting...")
                                .font(.system(size: 9))
                                .foregroundStyle(.secondary)
                        } else {
                            Text("\(server.metrics.count) metrics")
                                .font(.system(size: 9))
                                .foregroundStyle(.secondary)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
            }

            Spacer(minLength: 0)
        }
        .padding(12)
    }

    // MARK: Large — dots + names + top metrics

    private var largeView: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "server.rack")
                    .font(.subheadline)
                Text("Server Monitor")
                    .font(.subheadline.bold())
                Spacer()
                Text(summaryText)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }

            Divider()

            ForEach(entry.servers) { server in
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 6) {
                        Circle()
                            .fill(dotColor(for: server))
                            .frame(width: 8, height: 8)
                        Text(server.name)
                            .font(.caption.bold())
                        Spacer()
                        if let error = server.error {
                            Text("ERROR")
                                .font(.system(size: 9).bold())
                                .foregroundStyle(.red)
                        }
                    }

                    if server.error == nil {
                        // Show first 3 metrics
                        ForEach(Array(server.metrics.prefix(3))) { metric in
                            HStack {
                                Text(metric.label)
                                    .font(.system(size: 10))
                                    .foregroundStyle(.secondary)
                                Spacer()
                                Text(metric.formattedWithUnit)
                                    .font(.system(size: 10).monospacedDigit())
                            }
                        }
                    }
                }
                if server.id != entry.servers.last?.id {
                    Divider()
                }
            }

            Spacer(minLength: 0)
        }
        .padding(12)
    }

    // MARK: Helpers

    private func dotColor(for server: ServerSnapshot) -> Color {
        switch server.statusColor {
        case "green": return .green
        case "yellow": return .yellow
        case "red": return .red
        default: return .gray
        }
    }

    private var summaryText: String {
        let healthy = entry.servers.filter { $0.isHealthy }.count
        let total = entry.servers.count
        return "\(healthy)/\(total) healthy"
    }
}

// MARK: - Widget Configuration

struct ServerMonitorWidget: Widget {
    let kind = "ServerMonitorWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: ServerMonitorProvider()) { entry in
            ServerMonitorWidgetEntryView(entry: entry)
                .containerBackground(.fill.tertiary, for: .widget)
        }
        .configurationDisplayName("Server Monitor")
        .description("Monitor your server health at a glance.")
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge])
    }
}

@main
struct ServerMonitorWidgetBundle: WidgetBundle {
    var body: some Widget {
        ServerMonitorWidget()
    }
}
