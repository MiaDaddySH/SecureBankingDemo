public protocol TokenStoring: Sendable {
    func saveRefreshToken(_ token: String) throws
    func readRefreshToken() throws -> String?
    func deleteRefreshToken() throws
}
