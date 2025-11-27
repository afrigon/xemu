struct MemoryAccessType: OptionSet, Codable {
    let rawValue: Int
    
    static let none: MemoryAccessType = []
    static let read = MemoryAccessType(rawValue: 1 << 0)
    static let write = MemoryAccessType(rawValue: 1 << 1)
    static let readWrite: MemoryAccessType = [.read, .write]
}
