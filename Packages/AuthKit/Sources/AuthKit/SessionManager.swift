import Foundation

public actor SessionManager {
    private let tokenStore: TokenStoring
    private var accessToken: String?
    private var accessTokenExpiresAt: Date?

    public init(tokenStore: TokenStoring) {
        self.tokenStore = tokenStore
    }

    public func startSession(with tokens: AuthTokens) throws {
        accessToken = tokens.accessToken
        accessTokenExpiresAt = tokens.accessTokenExpiresAt
        try tokenStore.saveRefreshToken(tokens.refreshToken)
    }

    public func currentAccessToken() -> String? {
        accessToken
    }

    public func currentAccessTokenExpiresAt() -> Date? {
        accessTokenExpiresAt
    }

    public func isAccessTokenExpired(now: Date = Date()) -> Bool {
        guard let accessTokenExpiresAt else {
            return false
        }

        return now >= accessTokenExpiresAt
    }

    public func storedRefreshToken() throws -> String? {
        try tokenStore.readRefreshToken()
    }

    public func hasStoredRefreshToken() throws -> Bool {
        try tokenStore.readRefreshToken() != nil
    }

    public func restoreSessionAfterAppRestart() throws -> Bool {
        accessToken = nil
        accessTokenExpiresAt = nil
        return try tokenStore.readRefreshToken() != nil
    }

    public func updateAccessToken(_ token: String, expiresAt: Date? = nil) {
        accessToken = token
        accessTokenExpiresAt = expiresAt
    }

    public func replaceTokens(with tokens: AuthTokens) throws {
        try startSession(with: tokens)
    }

    public func logout() throws {
        accessToken = nil
        accessTokenExpiresAt = nil
        try tokenStore.deleteRefreshToken()
    }
}
