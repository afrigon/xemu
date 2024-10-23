public enum Arch {
    case mos6502
    
    public var stackBaseAddress: Int {
        switch self {
            case .mos6502:
                0x0100
        }
    }
    
    public var programCounterSize: Int {
        switch self {
            case .mos6502: 2
        }
    }
}
