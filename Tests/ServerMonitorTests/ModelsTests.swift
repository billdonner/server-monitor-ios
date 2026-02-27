import XCTest
@testable import Shared

final class ModelsTests: XCTestCase {

    // MARK: - StatusResponse

    func testStatusResponseDecoding() throws {
        let json = """
        {
            "servers": [
                {
                    "name": "Test Server",
                    "url": "http://localhost:9810/metrics",
                    "poll_every": 15,
                    "last_updated": 1708354200.5,
                    "metrics": [
                        {
                            "key": "requests",
                            "label": "Requests",
                            "value": 42,
                            "unit": "req/s"
                        }
                    ],
                    "error": null
                }
            ],
            "timestamp": 1708354205.8
        }
        """.data(using: .utf8)!

        let response = try JSONDecoder().decode(StatusResponse.self, from: json)
        XCTAssertEqual(response.servers.count, 1)
        XCTAssertEqual(response.timestamp, 1708354205.8, accuracy: 0.01)
    }

    // MARK: - ServerSnapshot

    func testServerSnapshotDecoding() throws {
        let json = """
        {
            "name": "Redis",
            "url": "localhost:6379",
            "poll_every": 10,
            "last_updated": 1708354198.3,
            "metrics": [],
            "error": null
        }
        """.data(using: .utf8)!

        let server = try JSONDecoder().decode(ServerSnapshot.self, from: json)
        XCTAssertEqual(server.name, "Redis")
        XCTAssertEqual(server.url, "localhost:6379")
        XCTAssertEqual(server.pollEvery, 10)
        XCTAssertEqual(server.lastUpdated!, 1708354198.3, accuracy: 0.01)
        XCTAssertNil(server.error)
        XCTAssertTrue(server.metrics.isEmpty)
    }

    func testServerSnapshotWithError() throws {
        let json = """
        {
            "name": "Down Server",
            "url": "http://localhost:9999/metrics",
            "poll_every": 15,
            "last_updated": 1708354200.0,
            "metrics": [],
            "error": "Connection refused"
        }
        """.data(using: .utf8)!

        let server = try JSONDecoder().decode(ServerSnapshot.self, from: json)
        XCTAssertEqual(server.error, "Connection refused")
        XCTAssertFalse(server.isHealthy)
        XCTAssertEqual(server.statusColor, "red")
    }

    func testServerSnapshotHealthy() throws {
        let json = """
        {
            "name": "Healthy",
            "url": "http://localhost:9810/metrics",
            "poll_every": 15,
            "last_updated": 1708354200.0,
            "metrics": [{"key": "up", "label": "Up", "value": 1}],
            "error": null
        }
        """.data(using: .utf8)!

        let server = try JSONDecoder().decode(ServerSnapshot.self, from: json)
        XCTAssertTrue(server.isHealthy)
        XCTAssertEqual(server.statusColor, "green")
    }

    func testServerSnapshotWaiting() throws {
        let json = """
        {
            "name": "New Server",
            "url": "http://localhost:9810/metrics",
            "poll_every": 15,
            "last_updated": null,
            "metrics": [],
            "error": null
        }
        """.data(using: .utf8)!

        let server = try JSONDecoder().decode(ServerSnapshot.self, from: json)
        XCTAssertTrue(server.isWaiting)
        XCTAssertEqual(server.statusColor, "gray")
        XCTAssertEqual(server.lastUpdatedFormatted, "waiting...")
    }

    func testServerSnapshotId() throws {
        let json = """
        {
            "name": "UniqueServer",
            "url": "http://localhost:9810/metrics",
            "poll_every": 15,
            "last_updated": null,
            "metrics": [],
            "error": null
        }
        """.data(using: .utf8)!

        let server = try JSONDecoder().decode(ServerSnapshot.self, from: json)
        XCTAssertEqual(server.id, "UniqueServer")
    }

    // MARK: - MetricValue

    func testMetricValueInt() throws {
        let json = "42".data(using: .utf8)!
        let value = try JSONDecoder().decode(MetricValue.self, from: json)
        XCTAssertEqual(value, .int(42))
        XCTAssertEqual(value.doubleValue, 42.0)
    }

    func testMetricValueDouble() throws {
        let json = "3.14".data(using: .utf8)!
        let value = try JSONDecoder().decode(MetricValue.self, from: json)
        XCTAssertEqual(value, .double(3.14))
        XCTAssertEqual(value.doubleValue!, 3.14, accuracy: 0.001)
    }

    func testMetricValueString() throws {
        let json = "\"master\"".data(using: .utf8)!
        let value = try JSONDecoder().decode(MetricValue.self, from: json)
        XCTAssertEqual(value, .string("master"))
        XCTAssertNil(value.doubleValue)
    }

    func testMetricValueRoundTrip() throws {
        let values: [MetricValue] = [.int(42), .double(3.14), .string("test")]
        for original in values {
            let data = try JSONEncoder().encode(original)
            let decoded = try JSONDecoder().decode(MetricValue.self, from: data)
            XCTAssertEqual(decoded, original)
        }
    }

    // MARK: - Metric

    func testMetricDecoding() throws {
        let json = """
        {
            "key": "memory",
            "label": "Memory",
            "value": 67.3,
            "unit": "MB",
            "color": "green",
            "warn_above": 512,
            "warn_below": null
        }
        """.data(using: .utf8)!

        let metric = try JSONDecoder().decode(Metric.self, from: json)
        XCTAssertEqual(metric.key, "memory")
        XCTAssertEqual(metric.label, "Memory")
        XCTAssertEqual(metric.unit, "MB")
        XCTAssertEqual(metric.color, "green")
        XCTAssertEqual(metric.warnAbove, 512)
        XCTAssertNil(metric.warnBelow)
        XCTAssertFalse(metric.isWarning) // 67.3 < 512
    }

    func testMetricWarningAbove() throws {
        let json = """
        {
            "key": "memory",
            "label": "Memory",
            "value": 600,
            "unit": "MB",
            "warn_above": 512
        }
        """.data(using: .utf8)!

        let metric = try JSONDecoder().decode(Metric.self, from: json)
        XCTAssertTrue(metric.isWarning)
        XCTAssertEqual(metric.computedColor, "red")
    }

    func testMetricWarningBelow() throws {
        let json = """
        {
            "key": "hit_rate",
            "label": "Hit Rate",
            "value": 85.2,
            "unit": "%",
            "warn_below": 90
        }
        """.data(using: .utf8)!

        let metric = try JSONDecoder().decode(Metric.self, from: json)
        XCTAssertTrue(metric.isWarning)
    }

    func testMetricFormattedValueInt() throws {
        let json = """
        {"key": "count", "label": "Count", "value": 42}
        """.data(using: .utf8)!

        let metric = try JSONDecoder().decode(Metric.self, from: json)
        XCTAssertEqual(metric.formattedValue, "42")
        XCTAssertEqual(metric.formattedWithUnit, "42")
    }

    func testMetricFormattedValueDouble() throws {
        let json = """
        {"key": "rate", "label": "Rate", "value": 95.7, "unit": "%"}
        """.data(using: .utf8)!

        let metric = try JSONDecoder().decode(Metric.self, from: json)
        XCTAssertEqual(metric.formattedValue, "95.7")
        XCTAssertEqual(metric.formattedWithUnit, "95.7 %")
    }

    func testMetricFormattedValueString() throws {
        let json = """
        {"key": "role", "label": "Role", "value": "master"}
        """.data(using: .utf8)!

        let metric = try JSONDecoder().decode(Metric.self, from: json)
        XCTAssertEqual(metric.formattedValue, "master")
    }

    func testMetricOptionalFields() throws {
        let json = """
        {"key": "simple", "label": "Simple", "value": 1}
        """.data(using: .utf8)!

        let metric = try JSONDecoder().decode(Metric.self, from: json)
        XCTAssertNil(metric.unit)
        XCTAssertNil(metric.color)
        XCTAssertNil(metric.warnAbove)
        XCTAssertNil(metric.warnBelow)
        XCTAssertEqual(metric.computedColor, "green")
    }

    // MARK: - Sticky Warning (hadError)

    func testServerSnapshotRecoveredIsWarned() throws {
        let json = """
        {
            "name": "Recovered",
            "url": "http://localhost:9810/metrics",
            "poll_every": 15,
            "last_updated": 1708354200.0,
            "metrics": [{"key": "up", "label": "Up", "value": 1}],
            "error": null,
            "had_error": true
        }
        """.data(using: .utf8)!

        let server = try JSONDecoder().decode(ServerSnapshot.self, from: json)
        XCTAssertTrue(server.isWarned)
        XCTAssertTrue(server.isHealthy)
        XCTAssertEqual(server.statusColor, "yellow")
    }

    func testServerSnapshotMissingHadErrorBackwardCompat() throws {
        let json = """
        {
            "name": "OldServer",
            "url": "http://localhost:9810/metrics",
            "poll_every": 15,
            "last_updated": 1708354200.0,
            "metrics": [{"key": "up", "label": "Up", "value": 1}],
            "error": null
        }
        """.data(using: .utf8)!

        let server = try JSONDecoder().decode(ServerSnapshot.self, from: json)
        XCTAssertFalse(server.isWarned)
        XCTAssertNil(server.hadError)
        XCTAssertEqual(server.statusColor, "green")
    }

    func testServerSnapshotHadErrorWithActiveError() throws {
        let json = """
        {
            "name": "StillDown",
            "url": "http://localhost:9810/metrics",
            "poll_every": 15,
            "last_updated": 1708354200.0,
            "metrics": [],
            "error": "Connection refused",
            "had_error": true
        }
        """.data(using: .utf8)!

        let server = try JSONDecoder().decode(ServerSnapshot.self, from: json)
        XCTAssertFalse(server.isWarned)
        XCTAssertEqual(server.statusColor, "red")
    }

    // MARK: - Full Round-Trip

    func testFullResponseRoundTrip() throws {
        let json = """
        {
            "servers": [
                {
                    "name": "card-engine",
                    "url": "http://127.0.0.1:9810/metrics",
                    "poll_every": 15,
                    "last_updated": 1708354200.5,
                    "metrics": [
                        {"key": "games", "label": "Games", "value": 42, "unit": "count"},
                        {"key": "memory", "label": "Memory", "value": 128.5, "unit": "MB", "warn_above": 512},
                        {"key": "status", "label": "Status", "value": "running"}
                    ],
                    "error": null
                },
                {
                    "name": "Redis",
                    "url": "localhost:6379",
                    "poll_every": 10,
                    "last_updated": 1708354198.3,
                    "metrics": [
                        {"key": "clients", "label": "Clients", "value": 5, "unit": "clients", "warn_above": 100}
                    ],
                    "error": null
                },
                {
                    "name": "Broken",
                    "url": "http://localhost:9999",
                    "poll_every": 30,
                    "last_updated": 1708354100.0,
                    "metrics": [],
                    "error": "Connection refused"
                }
            ],
            "timestamp": 1708354205.8
        }
        """.data(using: .utf8)!

        let response = try JSONDecoder().decode(StatusResponse.self, from: json)

        // Re-encode and decode
        let encoded = try JSONEncoder().encode(response)
        let decoded = try JSONDecoder().decode(StatusResponse.self, from: encoded)

        XCTAssertEqual(decoded.servers.count, 3)
        XCTAssertEqual(decoded.servers[0].name, "card-engine")
        XCTAssertEqual(decoded.servers[0].metrics.count, 3)
        XCTAssertTrue(decoded.servers[0].isHealthy)
        XCTAssertEqual(decoded.servers[1].name, "Redis")
        XCTAssertTrue(decoded.servers[1].isHealthy)
        XCTAssertEqual(decoded.servers[2].name, "Broken")
        XCTAssertFalse(decoded.servers[2].isHealthy)
        XCTAssertEqual(decoded.servers[2].error, "Connection refused")
    }
}
