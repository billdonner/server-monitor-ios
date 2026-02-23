# Server Monitor iOS

Native iOS + watchOS app + WidgetKit extensions for the server-monitor web dashboard.

## Architecture

- **iOS App target**: SwiftUI app with iPhone horizontal paging and iPad 2-column grid
- **iOS Widget target**: WidgetKit extension (small/medium/large + lock screen LED)
- **watchOS App target**: SwiftUI server list with colored status dots
- **watchOS Widget target**: WidgetKit complications (circular LED, corner, inline text)
- **Shared**: Models and StatusService compiled into all four targets

## Build & Run

```bash
# Generate Xcode project
cd ~/server-monitor-ios && xcodegen generate

# Build iOS app
xcodebuild -project ServerMonitor.xcodeproj -scheme ServerMonitor -destination 'platform=iOS Simulator,name=iPhone 16 Pro,OS=18.5' build

# Build watchOS app
xcodebuild -project ServerMonitor.xcodeproj -scheme ServerMonitorWatch -destination 'platform=watchOS Simulator,name=Apple Watch Series 11 (46mm)' build

# Run tests via SPM
cd ~/server-monitor-ios && swift test

# Start the server-monitor backend (required for live data)
cd ~/server-monitor && uv run python web.py
```

## API

- Production: `https://bd-server-monitor.fly.dev/api/status`
- Local: `http://127.0.0.1:9860/api/status`
- Requires `NSAllowsLocalNetworking = true` in ATS config

## Project Structure

| Directory | Purpose |
|-----------|---------|
| `App/` | Main iOS app views + onboarding |
| `Watch/` | watchOS app (server list) |
| `Widget/` | iOS WidgetKit extension |
| `WatchWidget/` | watchOS WidgetKit complications |
| `Shared/` | Models + StatusService (all targets) |
| `Assets.xcassets` | App icon, AccentColor (all targets) |
| `Tests/` | SPM test target |

## Targets & Signing

All four targets use automatic signing with team `NEAY582ME4`:

| Target | Bundle ID | Platform |
|--------|-----------|----------|
| ServerMonitor | `com.billdonner.ServerMonitor` | iOS 17+ |
| ServerMonitorWidgetExtension | `com.billdonner.ServerMonitor.Widget` | iOS 17+ |
| ServerMonitorWatch | `com.billdonner.ServerMonitor.watchkitapp` | watchOS 10+ |
| ServerMonitorWatchWidgetExtension | `com.billdonner.ServerMonitor.watchkitapp.widget` | watchOS 10+ |

## Onboarding

4-screen onboarding flow using SF Symbols, shown on first launch via `@AppStorage("hasSeenOnboarding")`. Triple-tap the status banner header to reset and re-show onboarding.

## Watch Complications

Three WidgetKit complications available on watchOS:

| Widget | Family | Display |
|--------|--------|---------|
| Status LED | `accessoryCircular` | Green/yellow/red dot |
| Server Status | `accessoryCorner` | server.rack icon + label |
| Server Inline | `accessoryInline` | "All OK" / "2 Down" text |

Complications refresh every 15 minutes via timeline provider. The watch app polls every 3 seconds when foregrounded.

## Error Highlighting

All dashboard frontends (web, terminal TUI, iOS, watchOS) share the same status model:
- **Green**: healthy
- **Yellow**: recovered from error (sticky warning)
- **Red**: currently down
- **Gray**: waiting for first poll

iOS: 2pt colored stroke + shadow overlay on `ServerCardView`.
watchOS: colored dots in server list + complication color.

## Port

Uses server-monitor at port **9860** (see port registry in ~/CLAUDE.md).
