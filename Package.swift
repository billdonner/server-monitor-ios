// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "ServerMonitor",
    platforms: [.iOS(.v17), .macOS(.v14)],
    targets: [
        .target(
            name: "Shared",
            path: "Shared"
        ),
        .testTarget(
            name: "ServerMonitorTests",
            dependencies: ["Shared"],
            path: "Tests/ServerMonitorTests"
        ),
    ]
)
