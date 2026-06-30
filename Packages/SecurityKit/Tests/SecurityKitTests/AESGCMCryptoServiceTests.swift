import Foundation
import XCTest
@testable import SecurityKit

final class AESGCMCryptoServiceTests: XCTestCase {
    func testEncryptAndDecryptReturnsOriginalData() throws {
        let keychain = MockKeychainStore()
        let service = AESGCMCryptoService(keychainStore: keychain)
        let plaintext = Data("Top secret note".utf8)

        let encryptedData = try service.encrypt(plaintext)
        let decryptedData = try service.decrypt(encryptedData)

        XCTAssertNotEqual(encryptedData, plaintext)
        XCTAssertEqual(decryptedData, plaintext)
    }

    func testGeneratedKeyIsStoredInKeychain() throws {
        let keychain = MockKeychainStore()
        let service = AESGCMCryptoService(
            keychainStore: keychain,
            service: "test.crypto",
            account: "noteKey",
            accessibility: .whenUnlocked
        )

        _ = try service.encrypt(Data("note".utf8))

        XCTAssertEqual(keychain.savedService, "test.crypto")
        XCTAssertEqual(keychain.savedAccount, "noteKey")
        XCTAssertEqual(keychain.savedAccessibility, .whenUnlocked)
        XCTAssertEqual(keychain.savedData?.count, 32)
    }

    func testDecryptWithDifferentKeyFails() throws {
        let firstService = AESGCMCryptoService(keychainStore: MockKeychainStore())
        let secondService = AESGCMCryptoService(keychainStore: MockKeychainStore())
        let encryptedData = try firstService.encrypt(Data("Top secret note".utf8))

        XCTAssertThrowsError(try secondService.decrypt(encryptedData)) { error in
            XCTAssertEqual(error as? CryptoServiceError, .decryptionFailed)
        }
    }
}

private final class MockKeychainStore: KeychainStoring, @unchecked Sendable {
    var storage: [String: Data] = [:]
    var savedData: Data?
    var savedService: String?
    var savedAccount: String?
    var savedAccessibility: KeychainAccessibility?

    func save(
        _ data: Data,
        service: String,
        account: String,
        accessibility: KeychainAccessibility
    ) throws {
        storage[key(service: service, account: account)] = data
        savedData = data
        savedService = service
        savedAccount = account
        savedAccessibility = accessibility
    }

    func read(service: String, account: String) throws -> Data {
        guard let data = storage[key(service: service, account: account)] else {
            throw KeychainError.itemNotFound
        }

        return data
    }

    func delete(service: String, account: String) throws {
        storage[key(service: service, account: account)] = nil
    }

    private func key(service: String, account: String) -> String {
        "\(service):\(account)"
    }
}
