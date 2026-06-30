import AuthKit
import Foundation

struct MockAuthService {
    enum MockAuthError: Error {
        case invalidCredentials
    }

    func login(username: String, password: String) async throws -> AuthTokens {
        let trimmedUsername = username.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !trimmedUsername.isEmpty, !password.isEmpty else {
            throw MockAuthError.invalidCredentials
        }

        try await Task.sleep(for: .milliseconds(500))

        return AuthTokens(
            accessToken: "demo-access-token-\(trimmedUsername)",
            refreshToken: "demo-refresh-token-\(UUID().uuidString)",
            accessTokenExpiresAt: Date().addingTimeInterval(15 * 60)
        )
    }
}
