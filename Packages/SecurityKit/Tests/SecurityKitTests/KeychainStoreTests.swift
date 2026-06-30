import Foundation
import XCTest
@testable import SecurityKit

final class KeychainStoreTests: XCTestCase {
    private let store = KeychainStore()
    private let service = "com.securebankingdemo.tests.keychain"

    override func tearDownWithError() throws {
        try? store.delete(service: service, account: "token")
        try? store.delete(service: service, account: "missing-token")
        try super.tearDownWithError()
    }

    func testSaveAndReadData() throws {
        let data = Data("access-token".utf8)

        try store.save(data, service: service, account: "token", accessibility: .whenUnlocked)

        let storedData = try store.read(service: service, account: "token")
        XCTAssertEqual(storedData, data)
    }

    func testSaveUpdatesExistingData() throws {
        let originalData = Data("old-token".utf8)
        let updatedData = Data("new-token".utf8)

        try store.save(originalData, service: service, account: "token", accessibility: .whenUnlocked)
        try store.save(updatedData, service: service, account: "token", accessibility: .whenUnlocked)

        let storedData = try store.read(service: service, account: "token")
        XCTAssertEqual(storedData, updatedData)
    }

    func testDeleteRemovesData() throws {
        try store.save(Data("access-token".utf8), service: service, account: "token", accessibility: .whenUnlocked)

        try store.delete(service: service, account: "token")

        XCTAssertThrowsError(try store.read(service: service, account: "token")) { error in
            XCTAssertEqual(error as? KeychainError, .itemNotFound)
        }
    }

    func testDeleteMissingDataDoesNotThrow() throws {
        XCTAssertNoThrow(try store.delete(service: service, account: "missing-token"))
    }
}
