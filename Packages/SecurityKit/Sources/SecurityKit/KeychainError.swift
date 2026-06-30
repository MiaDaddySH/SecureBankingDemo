import Foundation
import Security

public enum KeychainError: Error, Equatable, Sendable {
    case itemNotFound
    case unexpectedData
    case unhandledStatus(OSStatus)

    init(status: OSStatus) {
        switch status {
        case errSecItemNotFound:
            self = .itemNotFound
        default:
            self = .unhandledStatus(status)
        }
    }
}

extension KeychainError: LocalizedError {
    public var errorDescription: String? {
        switch self {
        case .itemNotFound:
            return "The requested keychain item was not found."
        case .unexpectedData:
            return "The keychain item did not contain Data."
        case .unhandledStatus(let status):
            return "Keychain operation failed with OSStatus \(status)."
        }
    }
}
