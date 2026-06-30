import Foundation
import SecurityKit

public final class KeychainTokenStore: TokenStoring, @unchecked Sendable {
    private let keychainStore: KeychainStoring
    private let service: String
    private let refreshTokenAccount: String
    private let accessibility: KeychainAccessibility

    public init(
        keychainStore: KeychainStoring,
        service: String = "com.securebankingdemo.auth",
        refreshTokenAccount: String = "refreshToken",
        accessibility: KeychainAccessibility = .whenUnlockedThisDeviceOnly
    ) {
        self.keychainStore = keychainStore
        self.service = service
        self.refreshTokenAccount = refreshTokenAccount
        self.accessibility = accessibility
    }

    public convenience init(
        service: String = "com.securebankingdemo.auth",
        refreshTokenAccount: String = "refreshToken",
        accessibility: KeychainAccessibility = .whenUnlockedThisDeviceOnly
    ) {
        self.init(
            keychainStore: KeychainStore(),
            service: service,
            refreshTokenAccount: refreshTokenAccount,
            accessibility: accessibility
        )
    }

    public func saveRefreshToken(_ token: String) throws {
        guard let data = token.data(using: .utf8) else {
            throw TokenStoreError.invalidRefreshTokenData
        }

        try keychainStore.save(
            data,
            service: service,
            account: refreshTokenAccount,
            accessibility: accessibility
        )
    }

    public func readRefreshToken() throws -> String? {
        do {
            let data = try keychainStore.read(service: service, account: refreshTokenAccount)

            guard let token = String(data: data, encoding: .utf8) else {
                throw TokenStoreError.invalidRefreshTokenData
            }

            return token
        } catch KeychainError.itemNotFound {
            return nil
        }
    }

    public func deleteRefreshToken() throws {
        try keychainStore.delete(service: service, account: refreshTokenAccount)
    }
}
