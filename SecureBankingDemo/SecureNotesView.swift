import SwiftUI

struct SecureNotesView: View {
    @StateObject private var viewModel: SecureNotesViewModel

    init(viewModel: SecureNotesViewModel) {
        _viewModel = StateObject(wrappedValue: viewModel)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Secure Notes")
                .font(.headline)

            TextEditor(text: $viewModel.noteText)
                .frame(minHeight: 120)
                .padding(8)
                .overlay {
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(.quaternary)
                }

            HStack(spacing: 12) {
                Button("保存加密笔记") {
                    viewModel.saveEncryptedNote()
                }
                .buttonStyle(.borderedProminent)
                .disabled(viewModel.noteText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)

                Button("读取并解密") {
                    viewModel.readEncryptedNote()
                }
                .buttonStyle(.bordered)
            }

            if let decryptedNote = viewModel.decryptedNote {
                VStack(alignment: .leading, spacing: 6) {
                    Text("解密结果")
                        .font(.subheadline.bold())

                    Text(decryptedNote)
                        .font(.callout)
                        .foregroundStyle(.secondary)
                }
            }

            if let statusMessage = viewModel.statusMessage {
                Text(statusMessage)
                    .font(.callout)
                    .foregroundStyle(viewModel.isShowingError ? .red : .secondary)
            }
        }
    }
}

#Preview {
    SecureNotesView(
        viewModel: SecureNotesViewModel(
            repository: try! SecureNoteRepository.live()
        )
    )
    .padding()
}
