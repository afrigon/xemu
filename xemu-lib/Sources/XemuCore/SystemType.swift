public enum SystemType: String, CaseIterable, Hashable, Codable, Identifiable, Sendable {
    
    /// Nintendo Entertainment System
    case nes
    
    /// Super Nintendo Entertainment System
    case superNes
    
    /// Nintendo Game Boy
    case gameBoy
    
    /// Nintendo Game Boy Color
    case gameBoyColor
    
    /// Nintendo Game Boy Advance
    case gameBoyAdvance
    
    /// Nintendo 64
    case nintendo64
    
    /// Nintendo DS
    case DS
    
    /// Nintendo Gamecube
    case gamecube
    
    /// Nintendo Wii
    case wii
    
    /// Nintendo Wii U
    case wiiu

    /// Nintendo Switch
    case `switch`

    /// Sega Dreamcast
    case dreamcast
    
    /// Sega Genesis / Mega Drive
    case segaGenesis
    
    public var id: String {
        rawValue
    }

    public var openVGDBIdentifier: String? {
        switch self {
            case .nes:
                "NES"
            case .superNes:
                "SNES"
            case .gameBoy:
                "GB"
            case .gameBoyColor:
                "GBC"
            case .gameBoyAdvance:
                "GBA"
            case .nintendo64:
                "N64"
            case .DS:
                "NDS"
            case .gamecube:
                "NGC"
            case .wii:
                "Wii"
            case .wiiu:
                nil
            case .switch:
                nil
            case .dreamcast:
                "DC"
            case .segaGenesis:
                "MD"
        }
    }
    
    public var title: String {
        switch self {
            case .nes:
                "Nintendo"
            case .superNes:
                "Super Nintendo"
            case .gameBoy:
                "Game Boy"
            case .gameBoyColor:
                "Game Boy Color"
            case .gameBoyAdvance:
                "Game Boy Advance"
            case .nintendo64:
                "Nintendo 64"
            case .DS:
                "Nintendo DS"
            case .gamecube:
                "Gamecube"
            case .wii:
                "Wii"
            case .wiiu:
                "Wii U"
            case .switch:
                "Switch"
            case .dreamcast:
                "Dreamcast"
            case .segaGenesis:
                "Sega Genesis"
        }
    }
    
    public var active: Bool {
        return switch self {
            case .nes:
                true
            default:
                false
        }
    }
    
    public static var allActiveCases: [SystemType] {
        allCases.filter(\.active)
    }
}
