import AuthKit
import SwiftUI

struct LoginView: View {
    @StateObject private var viewModel: LoginViewModel

    init(viewModel: LoginViewModel) {
        _viewModel = StateObject(wrappedValue: viewModel)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            VStack(alignment: .leading, spacing: 8) {
                Text("Secure Banking")
                    .font(.largeTitle.bold())

                Text("登录后会保存 refresh token，并把 access token 保留在内存中。")
                    .font(.body)
                    .foregroundStyle(.secondary)
            }

            VStack(spacing: 14) {
                TextField("用户名", text: $viewModel.username)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                    .textFieldStyle(.roundedBorder)

                SecureField("密码", text: $viewModel.password)
                    .textFieldStyle(.roundedBorder)
            }

            if let errorMessage = viewModel.errorMessage {
                Text(errorMessage)
                    .font(.callout)
                    .foregroundStyle(.red)
            }

            if viewModel.shouldShowBiometricUnlock {
                Button {
                    Task {
                        await viewModel.unlockWithBiometrics()
                    }
                } label: {
                    Text("Unlock with Face ID")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
                .controlSize(.large)
                .disabled(viewModel.isLoading)
            }

            Button {
                Task {
                    await viewModel.login()
                }
            } label: {
                if viewModel.isLoading {
                    ProgressView()
                        .frame(maxWidth: .infinity)
                } else {
                    Text("登录")
                        .frame(maxWidth: .infinity)
                }
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .disabled(viewModel.isLoginDisabled)

            Spacer()
        }
        .padding(24)
    }
}

#Preview {
    LoginView(
        viewModel: LoginViewModel(
            sessionController: AppSessionController(
                sessionManager: SessionManager(tokenStore: PreviewTokenStore())
            )
        )
    )
}
