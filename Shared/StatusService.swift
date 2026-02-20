import Foundation

/// Fetches server status from the server-monitor web dashboard API.
actor StatusService {
    static let shared = StatusService()

    var baseURL: String = "http://127.0.0.1:9860"

    private let decoder: JSONDecoder = {
        let d = JSONDecoder()
        return d
    }()

    func fetchStatus() async throws -> StatusResponse {
        guard let url = URL(string: "\(baseURL)/api/status") else {
            throw URLError(.badURL)
        }
        let (data, response) = try await URLSession.shared.data(from: url)
        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            throw URLError(.badServerResponse)
        }
        return try decoder.decode(StatusResponse.self, from: data)
    }
}
