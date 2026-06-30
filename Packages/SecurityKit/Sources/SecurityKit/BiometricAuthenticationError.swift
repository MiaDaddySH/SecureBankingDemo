import Foundation
import LocalAuthentication

public enum BiometricAuthenticationError: Error, Equatable, Sendable {
    case unavailable(underlyingDescription: String?)
    case authenticationFailed
    case userCancel
    case userFallback
    case lockout
    case notEnrolled
    case passcodeNotSet
    case systemCancel
    case unknown(code: Int)

    public static func unavailable(underlying: Error?) -> BiometricAuthenticationError {
        .unavailable(underlyingDescription: underlying?.localizedDescription)
    }

    init(error: LAError) {
        switch error.code {
        case .authenticationFailed:
            self = .authenticationFailed
        case .userCancel:
            self = .userCancel
        case .userFallback:
            self = .userFallback
        case .biometryLockout:
            self = .lockout
        case .biometryNotEnrolled:
            self = .notEnrolled
        case .passcodeNotSet:
            self = .passcodeNotSet
        case .systemCancel:
            self = .systemCancel
        case .biometryNotAvailable:
            self = .unavailable(underlying: error)
        default:
            self = .unknown(code: error.errorCode)
        }
    }
}

extension BiometricAuthenticationError: LocalizedError {
    public var errorDescription: String? {
        switch self {
        case .unavailable(let description):
            return description ?? "Biometric authentication is unavailable."
        case .authenticationFailed:
            return "Biometric authentication failed."
        case .userCancel:
            return "The user cancelled biometric authentication."
        case .userFallback:
            return "The user selected fallback authentication."
        case .lockout:
            return "Biometric authentication is locked out."
        case .notEnrolled:
            return "No biometric identity is enrolled."
        case .passcodeNotSet:
            return "Device passcode is not set."
        case .systemCancel:
            return "The system cancelled biometric authentication."
        case .unknown(let code):
            return "Biometric authentication failed with LAError code \(code)."
        }
    }
}
