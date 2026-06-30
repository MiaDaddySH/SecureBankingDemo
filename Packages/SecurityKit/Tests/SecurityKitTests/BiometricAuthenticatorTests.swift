import LocalAuthentication
import XCTest
@testable import SecurityKit

final class BiometricAuthenticatorTests: XCTestCase {
    func testCanAuthenticateReturnsTrueWhenPolicyIsAvailable() {
        let context = MockLAContext(canEvaluatePolicyResult: true)
        let authenticator = BiometricAuthenticator {
            context
        }

        XCTAssertTrue(authenticator.canAuthenticate())
    }

    func testAuthenticateSucceedsWhenContextEvaluationSucceeds() async throws {
        let context = MockLAContext(canEvaluatePolicyResult: true, evaluatePolicyResult: true)
        let authenticator = BiometricAuthenticator {
            context
        }

        try await authenticator.authenticate(reason: "Unlock")

        XCTAssertEqual(context.localizedReason, "Unlock")
        XCTAssertEqual(context.evaluatedPolicy, .deviceOwnerAuthenticationWithBiometrics)
    }

    func testAuthenticateThrowsUnavailableWhenPolicyCannotBeEvaluated() async {
        let context = MockLAContext(canEvaluatePolicyResult: false)
        let authenticator = BiometricAuthenticator {
            context
        }

        await XCTAssertThrowsErrorAsync(try await authenticator.authenticate(reason: "Unlock")) { error in
            guard case .unavailable = error as? BiometricAuthenticationError else {
                return XCTFail("Expected unavailable error, got \(error)")
            }
        }
    }

    func testAuthenticateMapsLAError() async {
        let context = MockLAContext(
            canEvaluatePolicyResult: true,
            evaluatePolicyError: LAError(.userCancel)
        )
        let authenticator = BiometricAuthenticator {
            context
        }

        await XCTAssertThrowsErrorAsync(try await authenticator.authenticate(reason: "Unlock")) { error in
            XCTAssertEqual(error as? BiometricAuthenticationError, .userCancel)
        }
    }
}

private final class MockLAContext: LAContextEvaluating, @unchecked Sendable {
    let canEvaluatePolicyResult: Bool
    let evaluatePolicyResult: Bool
    let evaluatePolicyError: Error?
    private(set) var evaluatedPolicy: LAPolicy?
    private(set) var localizedReason: String?

    init(
        canEvaluatePolicyResult: Bool,
        evaluatePolicyResult: Bool = false,
        evaluatePolicyError: Error? = nil
    ) {
        self.canEvaluatePolicyResult = canEvaluatePolicyResult
        self.evaluatePolicyResult = evaluatePolicyResult
        self.evaluatePolicyError = evaluatePolicyError
    }

    func canEvaluatePolicy(_ policy: LAPolicy, error: NSErrorPointer) -> Bool {
        canEvaluatePolicyResult
    }

    func evaluatePolicy(_ policy: LAPolicy, localizedReason: String) async throws -> Bool {
        evaluatedPolicy = policy
        self.localizedReason = localizedReason

        if let evaluatePolicyError {
            throw evaluatePolicyError
        }

        return evaluatePolicyResult
    }
}

private func XCTAssertThrowsErrorAsync(
    _ expression: @autoclosure () async throws -> some Any,
    _ errorHandler: (Error) -> Void,
    file: StaticString = #filePath,
    line: UInt = #line
) async {
    do {
        _ = try await expression()
        XCTFail("Expected expression to throw.", file: file, line: line)
    } catch {
        errorHandler(error)
    }
}
