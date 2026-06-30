import Foundation

public protocol APIClienting: Sendable {
    func send(_ endpoint: Endpoint) async throws -> Data
}

public final class APIClient: APIClienting, @unchecked Sendable {
    private let baseURL: URL
    private let urlSession: URLSession

    public init(baseURL: URL, urlSession: URLSession = .shared) {
        self.baseURL = baseURL
        self.urlSession = urlSession
    }

    public func send(_ endpoint: Endpoint) async throws -> Data {
        try await send(endpoint, additionalHeaders: [:])
    }

    func send(_ endpoint: Endpoint, additionalHeaders: [String: String]) async throws -> Data {
        let request = try makeRequest(for: endpoint, additionalHeaders: additionalHeaders)
        let (data, response) = try await urlSession.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIClientError.invalidResponse
        }

        guard (200..<300).contains(httpResponse.statusCode) else {
            throw APIClientError.httpStatus(httpResponse.statusCode, data: data)
        }

        return data
    }

    private func makeRequest(
        for endpoint: Endpoint,
        additionalHeaders: [String: String]
    ) throws -> URLRequest {
        guard var components = URLComponents(
            url: baseURL.appending(path: endpoint.path),
            resolvingAgainstBaseURL: false
        ) else {
            throw APIClientError.invalidURL
        }

        components.queryItems = endpoint.queryItems.isEmpty ? nil : endpoint.queryItems

        guard let url = components.url else {
            throw APIClientError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = endpoint.method.rawValue
        request.httpBody = endpoint.body

        endpoint.headers.forEach { key, value in
            request.setValue(value, forHTTPHeaderField: key)
        }

        additionalHeaders.forEach { key, value in
            request.setValue(value, forHTTPHeaderField: key)
        }

        return request
    }
}
