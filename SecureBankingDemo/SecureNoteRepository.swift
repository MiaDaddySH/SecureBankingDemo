import Foundation
import SecurityKit

struct SecureNoteRepository {
    private let cryptoService: CryptoServicing
    private let noteFileURL: URL

    init(cryptoService: CryptoServicing, noteFileURL: URL) {
        self.cryptoService = cryptoService
        self.noteFileURL = noteFileURL
    }

    static func live() throws -> SecureNoteRepository {
        let directoryURL = try FileManager.default.url(
            for: .applicationSupportDirectory,
            in: .userDomainMask,
            appropriateFor: nil,
            create: true
        )
        .appending(path: "SecureBankingDemo", directoryHint: .isDirectory)

        try FileManager.default.createDirectory(
            at: directoryURL,
            withIntermediateDirectories: true
        )

        return SecureNoteRepository(
            cryptoService: AESGCMCryptoService(keychainStore: KeychainStore()),
            noteFileURL: directoryURL.appending(path: "secure-note.enc")
        )
    }

    func save(note: String) throws {
        let plaintext = Data(note.utf8)
        let encryptedData = try cryptoService.encrypt(plaintext)
        try encryptedData.write(to: noteFileURL, options: .atomic)
    }

    func readNote() throws -> String {
        let encryptedData = try Data(contentsOf: noteFileURL)
        let decryptedData = try cryptoService.decrypt(encryptedData)

        guard let note = String(data: decryptedData, encoding: .utf8) else {
            throw SecureNoteRepositoryError.invalidPlaintext
        }

        return note
    }
}

enum SecureNoteRepositoryError: Error {
    case invalidPlaintext
}
