import Combine
import Foundation

@MainActor
final class LoginViewModel: ObservableObject {
    @Published var username = ""
    @Published var password = ""
    @Published private(set) var isLoading = false

    private let sessionController: AppSessionController

    init(sessionController: AppSessionController) {
        self.sessionController = sessionController
    }

    var errorMessage: String? {
        sessionController.lastErrorMessage
    }

    var isLoginDisabled: Bool {
        isLoading || username.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || password.isEmpty
    }

    func login() async {
        guard !isLoginDisabled else {
            return
        }

        isLoading = true
        defer { isLoading = false }

        await sessionController.login(username: username, password: password)
    }
}
