public enum ConsoleType: String, CaseIterable, Hashable, Codable {
    
    /// Nintendo Entertainment System
    case nes
    
    /// Super Nintendo Entertainment System
    case snes
    
    /// Nintendo Game Boy
    case gb
    
    /// Nintendo Game Boy Color
    case gbc
    
    /// Nintendo Game Boy Advance
    case gba
    
    /// Nintendo 64
    case n64
    
    /// Nintendo DS
    case ds
    
    /// Nintendo Gamecube
    case gc
    
    /// Nintendo Wii
    case wii

    /// Sega Dreamcast
    case dc
    
    /// Sega Genesis / Mega Drive
    case gen

    public var openVGDBIdentifier: String {
        return switch self {
            case .nes:
                "NES"
            case .snes:
                "SNES"
            case .gb:
                "GB"
            case .gbc:
                "GBC"
            case .gba:
                "GBA"
            case .n64:
                "N64"
            case .ds:
                "NDS"
            case .gc:
                "NGC"
            case .wii:
                "Wii"
            case .dc:
                "DC"
            case .gen:
                "MD"
        }
    }
    
    public var title: String {
        return switch self {
            case .nes:
                "Nintendo"
            case .snes:
                "Super Nintendo"
            case .gb:
                "Game Boy"
            case .gbc:
                "Game Boy Color"
            case .gba:
                "Game Boy Advance"
            case .n64:
                "Nintendo 64"
            case .ds:
                "Nintendo DS"
            case .gc:
                "Gamecube"
            case .wii:
                "Wii"
            case .dc:
                "Dreamcast"
            case .gen:
                "Sega Genesis"
        }
    }
    
    public var active: Bool {
        return switch self {
            case .nes:
                true
            default:
                true
        }
    }
    
    public static var allActiveCases: [ConsoleType] {
        allCases.filter(\.active)
    }
}
