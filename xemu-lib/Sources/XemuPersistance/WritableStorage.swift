import Foundation

public protocol WritableStorage {
    func write(for key: XemuIdentifier, _ data: Data) throws
}
