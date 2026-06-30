import AuthKit
import Combine
import Foundation
import SecurityKit

@MainActor
final class AppSessionController: ObservableObject {
    enum Route {
        case login
        case dashboard
    }

    @Published private(set) var route: Route = .login
    @Published private(set) var accessTokenPreview: String?
    @Published private(set) var canUnlockWithBiometrics = false
    @Published private(set) var isPreparingLaunch = false
    @Published private(set) var lastErrorMessage: String?

    private let authService: MockAuthService
    private let biometricAuthenticator: BiometricAuthenticating
    private let sessionManager: SessionManager

    init(
        authService: MockAuthService,
        biometricAuthenticator: BiometricAuthenticating,
        sessionManager: SessionManager
    ) {
        self.authService = authService
        self.biometricAuthenticator = biometricAuthenticator
        self.sessionManager = sessionManager
    }

    convenience init() {
        self.init(
            authService: MockAuthService(),
            biometricAuthenticator: BiometricAuthenticator(),
            sessionManager: SessionManager(tokenStore: KeychainTokenStore())
        )
    }

    convenience init(sessionManager: SessionManager) {
        self.init(
            authService: MockAuthService(),
            biometricAuthenticator: PreviewBiometricAuthenticator(),
            sessionManager: sessionManager
        )
    }

    func prepareLaunch() async {
        isPreparingLaunch = true
        defer { isPreparingLaunch = false }

        do {
            canUnlockWithBiometrics = try await sessionManager.hasStoredRefreshToken()
                && biometricAuthenticator.canAuthenticate()
        } catch {
            canUnlockWithBiometrics = false
        }
    }

    func login(username: String, password: String) async {
        lastErrorMessage = nil

        do {
            let tokens = try await authService.login(username: username, password: password)
            try await sessionManager.startSession(with: tokens)
            accessTokenPreview = tokens.accessToken
            canUnlockWithBiometrics = true
            route = .dashboard
        } catch {
            lastErrorMessage = "登录失败，请稍后重试。"
        }
    }

    func unlockWithBiometrics() async {
        lastErrorMessage = nil

        do {
            try await biometricAuthenticator.authenticate(reason: "Unlock SecureBankingDemo")

            guard let refreshToken = try await sessionManager.storedRefreshToken() else {
                canUnlockWithBiometrics = false
                lastErrorMessage = "没有可恢复的登录状态，请重新登录。"
                return
            }

            let tokens = try await authService.restoreSession(refreshToken: refreshToken)
            try await sessionManager.startSession(with: tokens)
            accessTokenPreview = tokens.accessToken
            canUnlockWithBiometrics = true
            route = .dashboard
        } catch let error as BiometricAuthenticationError {
            lastErrorMessage = biometricErrorMessage(for: error)
        } catch {
            lastErrorMessage = "解锁失败，请重新登录。"
        }
    }

    func logout() async {
        lastErrorMessage = nil

        do {
            try await sessionManager.logout()
            accessTokenPreview = nil
            canUnlockWithBiometrics = false
            route = .login
        } catch {
            lastErrorMessage = "退出登录失败，请重试。"
        }
    }

    private func biometricErrorMessage(for error: BiometricAuthenticationError) -> String {
        switch error {
        case .userCancel, .systemCancel:
            return "已取消 Face ID 解锁。"
        case .userFallback:
            return "请使用账号密码登录。"
        case .lockout:
            return "Face ID 已被锁定，请先使用系统密码解锁设备。"
        case .notEnrolled:
            return "当前设备未设置 Face ID。"
        case .passcodeNotSet:
            return "当前设备未设置系统密码，无法使用 Face ID。"
        case .unavailable:
            return "当前设备不可使用 Face ID。"
        case .authenticationFailed:
            return "Face ID 验证失败，请重试。"
        case .unknown:
            return "Face ID 解锁失败，请使用账号密码登录。"
        }
    }
}
