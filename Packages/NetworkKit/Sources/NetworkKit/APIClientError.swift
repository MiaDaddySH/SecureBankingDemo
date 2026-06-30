import Foundation

public enum APIClientError: Error, Equatable, Sendable {
    case invalidURL
    case invalidResponse
    case missingAccessToken
    case refreshFailed
    case httpStatus(Int, data: Data)
}
