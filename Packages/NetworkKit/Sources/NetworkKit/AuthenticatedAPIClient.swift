import Foundation

public protocol AccessTokenProviding: Sendable {
    func currentAccessToken() async throws -> String?
}

public protocol AccessTokenRefreshing: Sendable {
    func refreshAccessToken() async throws -> String
}

public final class AuthenticatedAPIClient: APIClienting, @unchecked Sendable {
    private let apiClient: APIClient
    private let tokenProvider: AccessTokenProviding
    private let tokenRefresher: AccessTokenRefreshing

    public init(
        apiClient: APIClient,
        tokenProvider: AccessTokenProviding,
        tokenRefresher: AccessTokenRefreshing
    ) {
        self.apiClient = apiClient
        self.tokenProvider = tokenProvider
        self.tokenRefresher = tokenRefresher
    }

    public func send(_ endpoint: Endpoint) async throws -> Data {
        let accessToken = try await requiredAccessToken()

        do {
            return try await send(endpoint, accessToken: accessToken)
        } catch APIClientError.httpStatus(401, _) {
            let refreshedAccessToken = try await refreshAccessToken()
            return try await send(endpoint, accessToken: refreshedAccessToken)
        }
    }

    private func send(_ endpoint: Endpoint, accessToken: String) async throws -> Data {
        try await apiClient.send(
            endpoint,
            additionalHeaders: [
                "Authorization": "Bearer \(accessToken)"
            ]
        )
    }

    private func requiredAccessToken() async throws -> String {
        guard let accessToken = try await tokenProvider.currentAccessToken(), !accessToken.isEmpty else {
            throw APIClientError.missingAccessToken
        }

        return accessToken
    }

    private func refreshAccessToken() async throws -> String {
        do {
            return try await tokenRefresher.refreshAccessToken()
        } catch {
            throw APIClientError.refreshFailed
        }
    }
}
