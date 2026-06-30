import Combine
import Foundation

@MainActor
final class DashboardViewModel: ObservableObject {
    private let sessionController: AppSessionController

    init(sessionController: AppSessionController) {
        self.sessionController = sessionController
    }

    var accessTokenSummary: String {
        guard let accessToken = sessionController.accessTokenPreview else {
            return "Access token: memory only"
        }

        return "Access token: \(accessToken)"
    }

    var errorMessage: String? {
        sessionController.lastErrorMessage
    }

    func logout() async {
        await sessionController.logout()
    }
}
