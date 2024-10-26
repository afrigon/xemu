import XemuFoundation

public enum BreakpointState {
    case enabled
    case disabled
    case enabledOnce
    case enabledForDeletion
}

public struct Breakpoint: Identifiable {
    public let id: Int
    public let address: u64
    public var state: BreakpointState
    
    public init(id: Int, address: u64, state: BreakpointState = .enabled) {
        self.id = id
        self.address = address
        self.state = state
    }
}
