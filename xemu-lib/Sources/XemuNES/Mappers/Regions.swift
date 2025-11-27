enum CPURegion: Codable {
    
    case prgRom
    
    case prgRam
    
    case prgPersistentRam
}

enum PPURegion: Codable {
    
    /// automatically selects rom / ram depending on current configuration
    case automatic
    
    case chrRom
    
    case chrRam
    
    case nametableRam
}
