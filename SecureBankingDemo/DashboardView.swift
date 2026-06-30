import AuthKit
import SwiftUI

struct DashboardView: View {
    @StateObject private var viewModel: DashboardViewModel

    init(viewModel: DashboardViewModel) {
        _viewModel = StateObject(wrappedValue: viewModel)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            VStack(alignment: .leading, spacing: 8) {
                Text("Secure Banking")
                    .font(.title.bold())

                Text("当前会话已建立，access token 仅保存在内存中。")
                    .font(.body)
                    .foregroundStyle(.secondary)
            }

            VStack(alignment: .leading, spacing: 10) {
                Text("会话状态")
                    .font(.headline)

                Text(viewModel.accessTokenSummary)
                    .font(.callout.monospaced())
                    .foregroundStyle(.secondary)
                    .textSelection(.enabled)
            }

            SecureNotesView(viewModel: viewModel.secureNotesViewModel)

            Spacer()

            if let errorMessage = viewModel.errorMessage {
                Text(errorMessage)
                    .font(.callout)
                    .foregroundStyle(.red)
            }

            Button {
                Task {
                    await viewModel.logout()
                }
            } label: {
                Text("退出登录")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
        }
        .padding(24)
    }
}

#Preview {
    DashboardView(
        viewModel: DashboardViewModel(
            sessionController: AppSessionController(
                sessionManager: SessionManager(tokenStore: PreviewTokenStore())
            )
        )
    )
}
