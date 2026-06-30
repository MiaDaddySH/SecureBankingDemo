import Combine
import Foundation

@MainActor
final class SecureNotesViewModel: ObservableObject {
    @Published var noteText = ""
    @Published private(set) var decryptedNote: String?
    @Published private(set) var statusMessage: String?
    @Published private(set) var isShowingError = false

    private let repository: SecureNoteRepository

    init(repository: SecureNoteRepository) {
        self.repository = repository
    }

    func saveEncryptedNote() {
        do {
            try repository.save(note: noteText)
            decryptedNote = nil
            isShowingError = false
            statusMessage = "笔记已加密保存。"
        } catch {
            isShowingError = true
            statusMessage = "保存失败，请重试。"
        }
    }

    func readEncryptedNote() {
        do {
            decryptedNote = try repository.readNote()
            isShowingError = false
            statusMessage = "笔记已读取并解密。"
        } catch {
            isShowingError = true
            statusMessage = "读取失败，请先保存一条加密笔记。"
        }
    }
}
