import Foundation
import XCTest
@testable import AuthKit

final class SessionManagerTests: XCTestCase {
    func testStartSessionKeepsAccessTokenInMemoryAndStoresRefreshToken() async throws {
        let tokenStore = MockTokenStore()
        let manager = SessionManager(tokenStore: tokenStore)
        let expiryDate = Date(timeIntervalSince1970: 100)
        let tokens = AuthTokens(
            accessToken: "access-token",
            refreshToken: "refresh-token",
            accessTokenExpiresAt: expiryDate
        )

        try await manager.startSession(with: tokens)

        let accessToken = await manager.currentAccessToken()
        let accessTokenExpiresAt = await manager.currentAccessTokenExpiresAt()
        XCTAssertEqual(accessToken, "access-token")
        XCTAssertEqual(accessTokenExpiresAt, expiryDate)
        XCTAssertEqual(tokenStore.refreshToken, "refresh-token")
    }

    func testRestoreSessionAfterAppRestartClearsAccessTokenButKeepsRefreshTokenAvailable() async throws {
        let tokenStore = MockTokenStore()
        tokenStore.refreshToken = "refresh-token"
        let manager = SessionManager(tokenStore: tokenStore)
        await manager.updateAccessToken("access-token")

        let hasRefreshToken = try await manager.restoreSessionAfterAppRestart()

        let accessToken = await manager.currentAccessToken()
        let refreshToken = try await manager.storedRefreshToken()
        XCTAssertTrue(hasRefreshToken)
        XCTAssertNil(accessToken)
        XCTAssertEqual(refreshToken, "refresh-token")
    }

    func testHasStoredRefreshTokenReturnsTrueWhenRefreshTokenExists() async throws {
        let tokenStore = MockTokenStore()
        tokenStore.refreshToken = "refresh-token"
        let manager = SessionManager(tokenStore: tokenStore)

        let hasRefreshToken = try await manager.hasStoredRefreshToken()

        XCTAssertTrue(hasRefreshToken)
    }

    func testLogoutClearsAccessTokenAndDeletesRefreshToken() async throws {
        let tokenStore = MockTokenStore()
        let manager = SessionManager(tokenStore: tokenStore)
        try await manager.startSession(
            with: AuthTokens(accessToken: "access-token", refreshToken: "refresh-token")
        )

        try await manager.logout()

        let accessToken = await manager.currentAccessToken()
        XCTAssertNil(accessToken)
        XCTAssertNil(tokenStore.refreshToken)
        XCTAssertTrue(tokenStore.didDeleteRefreshToken)
    }

    func testIsAccessTokenExpiredUsesExpirationDateWhenPresent() async {
        let tokenStore = MockTokenStore()
        let manager = SessionManager(tokenStore: tokenStore)
        await manager.updateAccessToken(
            "access-token",
            expiresAt: Date(timeIntervalSince1970: 100)
        )

        let expired = await manager.isAccessTokenExpired(now: Date(timeIntervalSince1970: 101))
        let valid = await manager.isAccessTokenExpired(now: Date(timeIntervalSince1970: 99))

        XCTAssertTrue(expired)
        XCTAssertFalse(valid)
    }
}

private final class MockTokenStore: TokenStoring, @unchecked Sendable {
    var refreshToken: String?
    var didDeleteRefreshToken = false

    func saveRefreshToken(_ token: String) throws {
        refreshToken = token
    }

    func readRefreshToken() throws -> String? {
        refreshToken
    }

    func deleteRefreshToken() throws {
        refreshToken = nil
        didDeleteRefreshToken = true
    }
}
