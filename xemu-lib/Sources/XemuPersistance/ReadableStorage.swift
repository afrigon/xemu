import Foundation

public protocol ReadableStorage {
    func read(key: XemuIdentifier) throws -> Data
}
