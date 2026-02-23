import SwiftUI

struct WatchContentView: View {
    @State private var servers: [ServerSnapshot] = []
    @State private var errorMessage: String?
    @State private var lastRefresh: Date?

    private let timer = Timer.publish(every: 3, on: .main, in: .common).autoconnect()

    var body: some View {
        NavigationStack {
            Group {
                if servers.isEmpty && errorMessage == nil {
                    ProgressView("Connecting...")
                } else if let errorMessage {
                    VStack(spacing: 8) {
                        Image(systemName: "wifi.exclamationmark")
                            .font(.title3)
                            .foregroundStyle(.red)
                        Text(errorMessage)
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                    }
                } else {
                    serverList
                }
            }
            .navigationTitle("Servers")
            .navigationBarTitleDisplayMode(.inline)
        }
        .task { await refresh() }
        .onReceive(timer) { _ in
            Task { await refresh() }
        }
    }

    private var serverList: some View {
        List(servers) { server in
            HStack(spacing: 8) {
                Circle()
                    .fill(dotColor(for: server))
                    .frame(width: 10, height: 10)
                VStack(alignment: .leading, spacing: 2) {
                    Text(server.name)
                        .font(.caption)
                        .lineLimit(1)
                    if let error = server.error {
                        Text(error)
                            .font(.system(size: 9))
                            .foregroundStyle(.red)
                            .lineLimit(1)
                    } else if server.isWaiting {
                        Text("waiting...")
                            .font(.system(size: 9))
                            .foregroundStyle(.secondary)
                    } else {
                        Text("\(server.metrics.count) metrics")
                            .font(.system(size: 9))
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
    }

    private func dotColor(for server: ServerSnapshot) -> Color {
        switch server.statusColor {
        case "green": return .green
        case "yellow": return .yellow
        case "red": return .red
        default: return .gray
        }
    }

    private func refresh() async {
        do {
            let response = try await StatusService.shared.fetchStatus()
            servers = response.servers
            lastRefresh = Date()
            errorMessage = nil
        } catch {
            if servers.isEmpty {
                errorMessage = error.localizedDescription
            }
        }
    }
}
