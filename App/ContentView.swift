import SwiftUI

struct ContentView: View {
    @Environment(\.horizontalSizeClass) private var sizeClass
    @AppStorage("hasSeenOnboarding") private var hasSeenOnboarding = false
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

    // MARK: - Header / Status Banner

    private var errorServers: [ServerSnapshot] {
        servers.filter { $0.error != nil }
    }

    private var warnedServers: [ServerSnapshot] {
        servers.filter { $0.isWarned }
    }

    private var bannerIsOK: Bool {
        !servers.isEmpty && errorServers.isEmpty && warnedServers.isEmpty && errorMessage == nil
    }

    private var header: some View {
        HStack {
            Image(systemName: bannerIsOK ? "checkmark.shield.fill" : "exclamationmark.triangle.fill")
                .font(.title2)
            VStack(alignment: .leading, spacing: 2) {
                Text(bannerTitle)
                    .font(.title3.bold())
                if !bannerDetail.isEmpty {
                    Text(bannerDetail)
                        .font(.caption)
                        .opacity(0.9)
                }
            }
            Spacer()
            if !warnedServers.isEmpty {
                Button {
                    Task { await clearWarnings() }
                } label: {
                    Text("Clear")
                        .font(.caption.bold())
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .background(.white.opacity(0.25))
                        .clipShape(Capsule())
                }
            }
            if let lastRefresh {
                Text(lastRefresh, style: .time)
                    .font(.caption)
                    .opacity(0.8)
            }
        }
        .foregroundStyle(.white)
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(bannerColor)
        .animation(.easeInOut(duration: 0.4), value: bannerIsOK)
        .onTapGesture(count: 3) {
            hasSeenOnboarding = false
        }
    }

    private var bannerColor: Color {
        if servers.isEmpty { return .gray }
        if errorMessage != nil || !errorServers.isEmpty { return .red }
        if !warnedServers.isEmpty { return .yellow }
        return .green
    }

    private var bannerTitle: String {
        if servers.isEmpty { return "Zerver Monitor" }
        if let errorMessage { return "Connection Error" }
        let errCount = errorServers.count
        if errCount > 0 { return "\(errCount) Server\(errCount > 1 ? "s" : "") Down" }
        let warnCount = warnedServers.count
        if warnCount > 0 { return "\(warnCount) Server\(warnCount > 1 ? "s" : "") Recovered" }
        return "All Systems OK"
    }

    private var bannerDetail: String {
        if servers.isEmpty { return "" }
        if errorMessage != nil { return errorMessage ?? "" }
        let errNames = errorServers.map(\.name)
        if !errNames.isEmpty { return errNames.joined(separator: ", ") }
        let warnNames = warnedServers.map(\.name)
        if !warnNames.isEmpty { return warnNames.joined(separator: ", ") }
        let healthy = servers.count
        return "\(healthy)/\(healthy) servers healthy"
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

    private func clearWarnings() async {
        try? await StatusService.shared.clearWarnings()
        await refresh()
    }
}

#Preview {
    ContentView()
}
