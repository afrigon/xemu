import XemuFoundation

public struct Breakpoint: Identifiable {
    public let id: u64
    
    let address: u64
}
