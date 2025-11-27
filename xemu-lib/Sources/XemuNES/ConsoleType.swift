public enum ConsoleType: CustomStringConvertible {
    
    case unknown
    
    /// Nintendo Entertainment System (NTSC)
    case nesNTSC
    
    /// Nintendo Entertainment System (PAL)
    case nesPAL
    
    /// Family Computer
    case famicom
    
    /// Dendy
    case dendy

    /// Nintendo Vs. System
    case vsSystem
    
    /// Nintendo Playchoice 10
    case playchoice
    
    /// Famicom Network System
    case famicomNetworkSystem
    
    public var description: String {
        switch self {
            case .unknown:
                "Unknown"
            case .nesNTSC:
                "Nintendo Entertainment System (NTSC)"
            case .nesPAL:
                "Nintendo Entertainment System (PAL)"
            case .famicom:
                "Family Computer"
            case .dendy:
                "Dendy"
            case .vsSystem:
                "Nintendo Vs. System"
            case .playchoice:
                "Nintendo Playchoice 10"
            case .famicomNetworkSystem:
                "Famicom Network System"
        }
    }
}
