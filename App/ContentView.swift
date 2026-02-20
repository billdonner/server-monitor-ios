import SwiftUI

struct ContentView: View {
    @Environment(\.horizontalSizeClass) private var sizeClass
    @State private var servers: [ServerSnapshot] = []
    @State private var lastRefresh: Date?
    @State private var errorMessage: String?

    private let timer = Timer.publish(every: 3, on: .main, in: .common).autoconnect()

    var body: some View {
        ZStack {
            Color(.systemGroupedBackground)
                .ignoresSafeArea()

            if servers.isEmpty && errorMessage == nil {
                ProgressView("Connecting to server-monitor...")
                    .font(.headline)
            } else if let errorMessage {
                VStack(spacing: 12) {
                    Image(systemName: "wifi.exclamationmark")
                        .font(.system(size: 48))
                        .foregroundStyle(.secondary)
                    Text("Connection Error")
                        .font(.title2.bold())
                    Text(errorMessage)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                    Text("Retrying every 3s...")
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                }
                .padding()
            } else {
                contentForSizeClass
            }
        }
        .task { await refresh() }
        .onReceive(timer) { _ in
            Task { await refresh() }
        }
    }

    @ViewBuilder
    private var contentForSizeClass: some View {
        if sizeClass == .compact {
            // iPhone: horizontal paging
            iPhonePagingView
        } else {
            // iPad: 2-column grid
            iPadGridView
        }
    }

    // MARK: - iPhone Paging

    private var iPhonePagingView: some View {
        VStack(spacing: 0) {
            header
            TabView {
                ForEach(servers) { server in
                    ServerCardView(server: server)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .automatic))
        }
    }

    // MARK: - iPad Grid

    private var iPadGridView: some View {
        VStack(spacing: 0) {
            header
            ScrollView {
                LazyVGrid(
                    columns: [
                        GridItem(.flexible(), spacing: 16),
                        GridItem(.flexible(), spacing: 16),
                    ],
                    spacing: 16
                ) {
                    ForEach(servers) { server in
                        ServerCardView(server: server)
                    }
                }
                .padding(16)
            }
        }
    }

    // MARK: - Header

    private var header: some View {
        HStack {
            Image(systemName: "server.rack")
                .font(.title2)
            Text("Server Monitor")
                .font(.title2.bold())
            Spacer()
            if let lastRefresh {
                Text(lastRefresh, style: .time)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Circle()
                .fill(errorMessage == nil ? .green : .red)
                .frame(width: 8, height: 8)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(.ultraThinMaterial)
    }

    // MARK: - Refresh

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

#Preview {
    ContentView()
}
