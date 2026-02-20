import SwiftUI

struct ServerCardView: View {
    let server: ServerSnapshot

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header: status dot + name + poll badge
            HStack(spacing: 8) {
                Circle()
                    .fill(statusDotColor)
                    .frame(width: 10, height: 10)
                Text(server.name)
                    .font(.headline)
                Spacer()
                Text("every \(server.pollEvery)s")
                    .font(.caption2)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(.quaternary)
                    .clipShape(Capsule())
            }

            // Error state
            if let error = server.error {
                HStack(spacing: 6) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundStyle(.red)
                    Text(error)
                        .font(.caption)
                        .foregroundStyle(.red)
                }
            }

            // Waiting state
            if server.isWaiting {
                HStack(spacing: 6) {
                    ProgressView()
                        .controlSize(.small)
                    Text("Waiting for first poll...")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            // Metrics
            if !server.metrics.isEmpty {
                Divider()
                ForEach(server.metrics) { metric in
                    MetricRowView(metric: metric)
                }
            }

            // Last updated
            HStack {
                Spacer()
                Text(server.lastUpdatedFormatted)
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }
        }
        .padding(16)
        .background {
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(Color(.secondarySystemGroupedBackground))
                .shadow(color: .black.opacity(0.08), radius: 4, y: 2)
        }
        .overlay {
            if server.error != nil {
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .stroke(.red, lineWidth: 2)
                    .shadow(color: .red.opacity(0.3), radius: 6)
            }
        }
    }

    private var statusDotColor: Color {
        switch server.statusColor {
        case "green": return .green
        case "yellow": return .yellow
        case "red": return .red
        default: return .gray
        }
    }
}

// MARK: - Metric Row

struct MetricRowView: View {
    let metric: Metric

    var body: some View {
        HStack {
            Text(metric.label)
                .font(.subheadline)
                .foregroundStyle(.secondary)
            Spacer()
            Text(metric.formattedWithUnit)
                .font(.subheadline.monospacedDigit().bold())
                .foregroundStyle(metricColor)
        }
    }

    private var metricColor: Color {
        switch metric.computedColor {
        case "red": return .red
        case "yellow": return .orange
        case "green": return .green
        default: return .primary
        }
    }
}

#Preview {
    ServerCardView(server: ServerSnapshot(
        name: "Test Server",
        url: "http://localhost:9847/metrics",
        pollEvery: 15,
        lastUpdated: Date().timeIntervalSince1970,
        metrics: [
            Metric(key: "uptime", label: "Uptime", value: .string("3d 2h"), unit: nil, color: "green", warnAbove: nil, warnBelow: nil),
            Metric(key: "requests", label: "Requests", value: .int(1234), unit: "req/s", color: nil, warnAbove: 5000, warnBelow: nil),
            Metric(key: "memory", label: "Memory", value: .double(67.3), unit: "MB", color: nil, warnAbove: 512, warnBelow: nil),
        ],
        error: nil
    ))
    .padding()
}
