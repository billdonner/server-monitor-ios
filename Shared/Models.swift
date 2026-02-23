import Foundation

// MARK: - API Response

/// Top-level response from GET /api/status
struct StatusResponse: Codable, Sendable {
    let servers: [ServerSnapshot]
    let timestamp: Double
}

// MARK: - Server Snapshot

struct ServerSnapshot: Codable, Identifiable, Sendable {
    let name: String
    let url: String
    let pollEvery: Int
    let lastUpdated: Double?
    let metrics: [Metric]
    let error: String?
    let hadError: Bool?

    var id: String { name }

    var isHealthy: Bool {
        error == nil && !metrics.isEmpty
    }

    var isWaiting: Bool {
        lastUpdated == nil && error == nil
    }

    /// Server recovered from a previous error but warning not yet cleared.
    var isWarned: Bool {
        hadError == true && error == nil
    }

    var statusColor: String {
        if isWaiting { return "gray" }
        if error != nil { return "red" }
        if hadError == true { return "yellow" }
        // Check if any metric is in warning state
        for metric in metrics {
            if metric.isWarning { return "yellow" }
        }
        return "green"
    }

    var lastUpdatedDate: Date? {
        guard let lastUpdated else { return nil }
        return Date(timeIntervalSince1970: lastUpdated)
    }

    var lastUpdatedFormatted: String {
        guard let date = lastUpdatedDate else { return "waiting..." }
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: date, relativeTo: Date())
    }

    enum CodingKeys: String, CodingKey {
        case name, url, metrics, error
        case pollEvery = "poll_every"
        case lastUpdated = "last_updated"
        case hadError = "had_error"
    }
}

// MARK: - Metric

struct Metric: Codable, Identifiable, Sendable {
    let key: String
    let label: String
    let value: MetricValue
    let unit: String?
    let color: String?
    let warnAbove: Double?
    let warnBelow: Double?

    var id: String { key }

    var isWarning: Bool {
        guard let numericValue = value.doubleValue else { return false }
        if let warnAbove, numericValue > warnAbove { return true }
        if let warnBelow, numericValue < warnBelow { return true }
        return false
    }

    var computedColor: String {
        if let color { return color }
        if isWarning { return "yellow" }
        return "green"
    }

    var formattedValue: String {
        switch value {
        case .int(let v):
            return "\(v)"
        case .double(let v):
            if v == v.rounded() {
                return "\(Int(v))"
            }
            return String(format: "%.1f", v)
        case .string(let v):
            return v
        }
    }

    var formattedWithUnit: String {
        if let unit {
            return "\(formattedValue) \(unit)"
        }
        return formattedValue
    }

    enum CodingKeys: String, CodingKey {
        case key, label, value, unit, color
        case warnAbove = "warn_above"
        case warnBelow = "warn_below"
    }
}

// MARK: - MetricValue

enum MetricValue: Codable, Sendable, Equatable {
    case int(Int)
    case double(Double)
    case string(String)

    var doubleValue: Double? {
        switch self {
        case .int(let v): return Double(v)
        case .double(let v): return v
        case .string: return nil
        }
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if let intVal = try? container.decode(Int.self) {
            self = .int(intVal)
        } else if let doubleVal = try? container.decode(Double.self) {
            self = .double(doubleVal)
        } else if let stringVal = try? container.decode(String.self) {
            self = .string(stringVal)
        } else {
            throw DecodingError.typeMismatch(
                MetricValue.self,
                DecodingError.Context(
                    codingPath: decoder.codingPath,
                    debugDescription: "Expected Int, Double, or String"
                )
            )
        }
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        switch self {
        case .int(let v): try container.encode(v)
        case .double(let v): try container.encode(v)
        case .string(let v): try container.encode(v)
        }
    }
}
