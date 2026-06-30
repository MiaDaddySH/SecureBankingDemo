public enum CryptoServiceError: Error, Equatable, Sendable {
    case sealedBoxEncodingFailed
    case decryptionFailed
}
