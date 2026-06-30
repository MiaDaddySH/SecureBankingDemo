import AuthKit
import SwiftUI

struct ContentView: View {
    @StateObject private var sessionController: AppSessionController

    @MainActor
    init() {
        _sessionController = StateObject(wrappedValue: AppSessionController())
    }

    @MainActor
    init(sessionController: AppSessionController) {
        _sessionController = StateObject(wrappedValue: sessionController)
    }

    var body: some View {
        Group {
            switch sessionController.route {
            case .login:
                LoginView(viewModel: LoginViewModel(sessionController: sessionController))
            case .dashboard:
                DashboardView(viewModel: DashboardViewModel(sessionController: sessionController))
            }
        }
        .task {
            await sessionController.prepareLaunch()
        }
    }
}

#Preview {
    ContentView(
        sessionController: AppSessionController(
            sessionManager: SessionManager(tokenStore: PreviewTokenStore())
        )
    )
}
