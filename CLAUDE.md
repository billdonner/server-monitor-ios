# Server Monitor iOS

Native iOS app + WidgetKit extension for the server-monitor web dashboard.

## Architecture

- **App target**: SwiftUI app with iPhone horizontal paging and iPad 2-column grid
- **Widget target**: WidgetKit extension showing server status at a glance
- **Shared**: Models and StatusService compiled into both targets

## Build & Run

```bash
# Generate Xcode project
cd ~/server-monitor-ios && xcodegen generate

# Run tests via SPM
cd ~/server-monitor-ios && swift test

# Start the server-monitor backend (required for live data)
cd ~/server-monitor && uv run python web.py
```

## API

Connects to `GET http://127.0.0.1:9860/api/status` for server metrics.
Requires `NSAllowsLocalNetworking = true` in ATS config.

## Project Structure

| Directory | Purpose |
|-----------|---------|
| `Shared/` | Models + StatusService (both targets) |
| `App/` | Main iOS app views |
| `Widget/` | WidgetKit extension |
| `Tests/` | SPM test target |

## Port

Uses server-monitor at port **9860** (see ~/alities/CLAUDE.md port registry).
