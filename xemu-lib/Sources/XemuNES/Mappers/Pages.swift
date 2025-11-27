struct CPUPage: Codable {
    var region: CPURegion?
    var base: Int
    var access: MemoryAccessType

    static let unmapped = CPUPage(base: 0, access: .none)
}

struct PPUPage: Codable {
    var region: PPURegion?
    var base: Int
    var access: MemoryAccessType
    
    static let unmapped = PPUPage(base: 0, access: .none)
}
