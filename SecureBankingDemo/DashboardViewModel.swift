import Combine
import Foundation

@MainActor
final class DashboardViewModel: ObservableObject {
    private let sessionController: AppSessionController
    let secureNotesViewModel: SecureNotesViewModel

    init(sessionController: AppSessionController) {
        self.sessionController = sessionController
        self.secureNotesViewModel = DashboardViewModel.makeSecureNotesViewModel()
    }

    init(sessionController: AppSessionController, secureNotesViewModel: SecureNotesViewModel) {
        self.sessionController = sessionController
        self.secureNotesViewModel = secureNotesViewModel
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

    private static func makeSecureNotesViewModel() -> SecureNotesViewModel {
        do {
            return SecureNotesViewModel(repository: try SecureNoteRepository.live())
        } catch {
            let temporaryURL = FileManager.default.temporaryDirectory.appending(path: "secure-note-preview.enc")
            return SecureNotesViewModel(
                repository: SecureNoteRepository(
                    cryptoService: PreviewCryptoService(),
                    noteFileURL: temporaryURL
                )
            )
        }
    }
}
