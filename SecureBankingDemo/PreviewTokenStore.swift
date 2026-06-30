import AuthKit

final class PreviewTokenStore: TokenStoring, @unchecked Sendable {
    private var refreshToken: String?

    func saveRefreshToken(_ token: String) throws {
        refreshToken = token
    }

    func readRefreshToken() throws -> String? {
        refreshToken
    }

    func deleteRefreshToken() throws {
        refreshToken = nil
    }
}
