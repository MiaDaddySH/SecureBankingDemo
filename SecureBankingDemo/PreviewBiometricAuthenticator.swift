import SecurityKit

struct PreviewBiometricAuthenticator: BiometricAuthenticating {
    func canAuthenticate() -> Bool {
        true
    }

    func authenticate(reason: String) async throws {}
}
