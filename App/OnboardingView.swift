import SwiftUI

struct OnboardingView: View {
    @AppStorage("hasSeenOnboarding") private var hasSeenOnboarding = false
    @State private var currentPage = 0

    var body: some View {
        ZStack(alignment: .topTrailing) {
            TabView(selection: $currentPage) {
                OnboardingPage(
                    symbolName: "server.rack",
                    symbolRendering: .multicolor,
                    symbolColor: .blue,
                    headline: "Server Monitor",
                    bodyText: "Keep an eye on all your servers from one place. Real-time status for HTTP, Redis, and PostgreSQL — at a glance."
                )
                .tag(0)

                statusPage
                    .tag(1)

                OnboardingPage(
                    symbolName: "widget.small",
                    symbolRendering: .hierarchical,
                    symbolColor: .indigo,
                    headline: "Glanceable Widgets",
                    bodyText: "Add home screen widgets to see server health without opening the app. A lock screen LED turns red the moment something goes wrong."
                )
                .tag(2)

                getStartedPage
                    .tag(3)
            }
            .tabViewStyle(.page(indexDisplayMode: .always))
            .indexViewStyle(.page(backgroundDisplayMode: .always))

            if currentPage < 3 {
                Button("Skip") {
                    hasSeenOnboarding = true
                }
                .font(.body.bold())
                .foregroundStyle(.secondary)
                .padding(.horizontal, 24)
                .padding(.top, 16)
            }
        }
        .background(Color(.systemGroupedBackground).ignoresSafeArea())
    }

    // MARK: - Screen 2: Traffic Light Status

    private var statusPage: some View {
        VStack(spacing: 32) {
            Spacer()

            HStack(spacing: 24) {
                statusDot(.green, symbol: "checkmark.circle.fill")
                statusDot(.yellow, symbol: "exclamationmark.circle.fill")
                statusDot(.red, symbol: "xmark.circle.fill")
            }

            VStack(spacing: 12) {
                Text("Instant Health Check")
                    .font(.title.bold())

                Text("Green means healthy. Yellow means it recovered from a problem. Red means it's down right now. Every server polls automatically.")
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
            }

            Spacer()
            Spacer()
        }
    }

    private func statusDot(_ color: Color, symbol: String) -> some View {
        Image(systemName: symbol)
            .font(.system(size: 52))
            .foregroundStyle(color)
            .symbolRenderingMode(.hierarchical)
    }

    // MARK: - Screen 4: Get Started

    private var getStartedPage: some View {
        VStack(spacing: 32) {
            Spacer()

            Image(systemName: "checkmark.shield.fill")
                .font(.system(size: 80))
                .symbolRenderingMode(.palette)
                .foregroundStyle(.white, .green)

            VStack(spacing: 12) {
                Text("You're All Set")
                    .font(.title.bold())

                Text("The dashboard connects automatically and refreshes every 3 seconds. No setup needed.")
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
            }

            Button {
                hasSeenOnboarding = true
            } label: {
                Text("Start Monitoring")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
            }
            .buttonStyle(.borderedProminent)
            .padding(.horizontal, 40)

            Spacer()
            Spacer()
        }
    }
}

// MARK: - Reusable Page

private struct OnboardingPage: View {
    let symbolName: String
    let symbolRendering: SymbolRenderingMode
    let symbolColor: Color
    let headline: String
    let bodyText: String

    var body: some View {
        VStack(spacing: 32) {
            Spacer()

            Image(systemName: symbolName)
                .font(.system(size: 80))
                .symbolRenderingMode(symbolRendering)
                .foregroundStyle(symbolColor)

            VStack(spacing: 12) {
                Text(headline)
                    .font(.title.bold())

                Text(bodyText)
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
            }

            Spacer()
            Spacer()
        }
    }
}

#Preview {
    OnboardingView()
}
