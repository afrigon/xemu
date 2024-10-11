import Foundation

public class FileSystemStorage: LocalStorage {
    let root: URL
    
    public init(root: URL) {
        self.root = root
    }
    
    public func read(key: XemuIdentifier) throws -> Data {
        let url = root.appendingPathComponent(key.value)
        return try Data(contentsOf: url)
    }

    public func write(for key: XemuIdentifier, _ data: Data) throws {
        let url = root.appendingPathComponent(key.value)
        try data.write(to: url, options: .atomic)
    }
}
