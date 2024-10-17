import Foundation
import CryptoKit

public struct XemuIdentifier: Codable {
    public let value: String
    
    public init(_ value: String) {
        self.value = value
    }
    
    public init(from data: Data) {
        value = Insecure.MD5
            .hash(data: data)
            .map { String(format: "%02hhx", $0) }
            .joined()
    }
}
