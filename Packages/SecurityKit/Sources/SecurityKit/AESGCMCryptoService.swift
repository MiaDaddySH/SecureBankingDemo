import CryptoKit
import Foundation

public protocol CryptoServicing: Sendable {
    func encrypt(_ data: Data) throws -> Data
    func decrypt(_ encryptedData: Data) throws -> Data
}

public final class AESGCMCryptoService: CryptoServicing, @unchecked Sendable {
    private let keychainStore: KeychainStoring
    private let service: String
    private let account: String
    private let accessibility: KeychainAccessibility

    public init(
        keychainStore: KeychainStoring,
        service: String = "com.securebankingdemo.crypto",
        account: String = "secureNotesKey",
        accessibility: KeychainAccessibility = .whenUnlockedThisDeviceOnly
    ) {
        self.keychainStore = keychainStore
        self.service = service
        self.account = account
        self.accessibility = accessibility
    }

    public func encrypt(_ data: Data) throws -> Data {
        let key = try symmetricKey()
        let sealedBox = try AES.GCM.seal(data, using: key)

        guard let combined = sealedBox.combined else {
            throw CryptoServiceError.sealedBoxEncodingFailed
        }

        return combined
    }

    public func decrypt(_ encryptedData: Data) throws -> Data {
        let key = try symmetricKey()

        do {
            let sealedBox = try AES.GCM.SealedBox(combined: encryptedData)
            return try AES.GCM.open(sealedBox, using: key)
        } catch {
            throw CryptoServiceError.decryptionFailed
        }
    }

    private func symmetricKey() throws -> SymmetricKey {
        do {
            let keyData = try keychainStore.read(service: service, account: account)
            return SymmetricKey(data: keyData)
        } catch KeychainError.itemNotFound {
            let key = SymmetricKey(size: .bits256)
            let keyData = key.withUnsafeBytes { buffer in
                Data(buffer)
            }

            try keychainStore.save(
                keyData,
                service: service,
                account: account,
                accessibility: accessibility
            )

            return key
        }
    }
}
