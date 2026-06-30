import Foundation
import SecurityKit

struct PreviewCryptoService: CryptoServicing {
    func encrypt(_ data: Data) throws -> Data {
        data
    }

    func decrypt(_ encryptedData: Data) throws -> Data {
        encryptedData
    }
}
