import Foundation
import SecurityKit
import XCTest
@testable import AuthKit

final class KeychainTokenStoreTests: XCTestCase {
    func testSaveRefreshTokenStoresUTF8DataInKeychain() throws {
        let keychain = MockKeychainStore()
        let store = KeychainTokenStore(
            keychainStore: keychain,
            service: "test.auth",
            refreshTokenAccount: "refresh"
        )

        try store.saveRefreshToken("refresh-token")

        XCTAssertEqual(keychain.savedData, Data("refresh-token".utf8))
        XCTAssertEqual(keychain.savedService, "test.auth")
        XCTAssertEqual(keychain.savedAccount, "refresh")
        XCTAssertEqual(keychain.savedAccessibility, .whenUnlockedThisDeviceOnly)
    }

    func testReadRefreshTokenReturnsStoredToken() throws {
        let keychain = MockKeychainStore()
        keychain.dataToRead = Data("refresh-token".utf8)
        let store = KeychainTokenStore(keychainStore: keychain)

        let token = try store.readRefreshToken()

        XCTAssertEqual(token, "refresh-token")
    }

    func testReadRefreshTokenReturnsNilWhenKeychainItemIsMissing() throws {
        let keychain = MockKeychainStore()
        keychain.errorToThrowOnRead = KeychainError.itemNotFound
        let store = KeychainTokenStore(keychainStore: keychain)

        let token = try store.readRefreshToken()

        XCTAssertNil(token)
    }

    func testDeleteRefreshTokenDeletesKeychainItem() throws {
        let keychain = MockKeychainStore()
        let store = KeychainTokenStore(
            keychainStore: keychain,
            service: "test.auth",
            refreshTokenAccount: "refresh"
        )

        try store.deleteRefreshToken()

        XCTAssertEqual(keychain.deletedService, "test.auth")
        XCTAssertEqual(keychain.deletedAccount, "refresh")
    }
}

private final class MockKeychainStore: KeychainStoring, @unchecked Sendable {
    var savedData: Data?
    var savedService: String?
    var savedAccount: String?
    var savedAccessibility: KeychainAccessibility?
    var dataToRead: Data?
    var errorToThrowOnRead: Error?
    var deletedService: String?
    var deletedAccount: String?

    func save(
        _ data: Data,
        service: String,
        account: String,
        accessibility: KeychainAccessibility
    ) throws {
        savedData = data
        savedService = service
        savedAccount = account
        savedAccessibility = accessibility
    }

    func read(service: String, account: String) throws -> Data {
        if let errorToThrowOnRead {
            throw errorToThrowOnRead
        }

        return dataToRead ?? Data()
    }

    func delete(service: String, account: String) throws {
        deletedService = service
        deletedAccount = account
    }
}
