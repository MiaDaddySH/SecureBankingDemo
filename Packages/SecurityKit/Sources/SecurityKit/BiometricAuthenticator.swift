import Foundation
import LocalAuthentication

public protocol BiometricAuthenticating: Sendable {
    func canAuthenticate() -> Bool
    func authenticate(reason: String) async throws
}

public final class BiometricAuthenticator: BiometricAuthenticating, @unchecked Sendable {
    private let contextProvider: @Sendable () -> LAContextEvaluating

    public init() {
        self.contextProvider = {
            LAContext()
        }
    }

    init(contextProvider: @escaping @Sendable () -> LAContextEvaluating) {
        self.contextProvider = contextProvider
    }

    public func canAuthenticate() -> Bool {
        let context = contextProvider()
        var error: NSError?
        return context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error)
    }

    public func authenticate(reason: String) async throws {
        let context = contextProvider()
        var error: NSError?

        guard context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) else {
            throw BiometricAuthenticationError.unavailable(underlying: error)
        }

        do {
            let success = try await context.evaluatePolicy(
                .deviceOwnerAuthenticationWithBiometrics,
                localizedReason: reason
            )

            guard success else {
                throw BiometricAuthenticationError.authenticationFailed
            }
        } catch let error as LAError {
            throw BiometricAuthenticationError(error: error)
        } catch {
            throw BiometricAuthenticationError.unavailable(underlying: error)
        }
    }
}

protocol LAContextEvaluating: Sendable {
    func canEvaluatePolicy(_ policy: LAPolicy, error: NSErrorPointer) -> Bool
    func evaluatePolicy(_ policy: LAPolicy, localizedReason: String) async throws -> Bool
}

extension LAContext: LAContextEvaluating {}
