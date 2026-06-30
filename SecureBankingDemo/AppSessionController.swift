import AuthKit
import Combine
import Foundation

@MainActor
final class AppSessionController: ObservableObject {
    enum Route {
        case login
        case dashboard
    }

    @Published private(set) var route: Route = .login
    @Published private(set) var accessTokenPreview: String?
    @Published private(set) var lastErrorMessage: String?

    private let authService: MockAuthService
    private let sessionManager: SessionManager

    init(
        authService: MockAuthService,
        sessionManager: SessionManager
    ) {
        self.authService = authService
        self.sessionManager = sessionManager
    }

    convenience init() {
        self.init(
            authService: MockAuthService(),
            sessionManager: SessionManager(tokenStore: KeychainTokenStore())
        )
    }

    convenience init(sessionManager: SessionManager) {
        self.init(
            authService: MockAuthService(),
            sessionManager: sessionManager
        )
    }

    func login(username: String, password: String) async {
        lastErrorMessage = nil

        do {
            let tokens = try await authService.login(username: username, password: password)
            try await sessionManager.startSession(with: tokens)
            accessTokenPreview = tokens.accessToken
            route = .dashboard
        } catch {
            lastErrorMessage = "登录失败，请稍后重试。"
        }
    }

    func logout() async {
        lastErrorMessage = nil

        do {
            try await sessionManager.logout()
            accessTokenPreview = nil
            route = .login
        } catch {
            lastErrorMessage = "退出登录失败，请重试。"
        }
    }
}
