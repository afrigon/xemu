import XemuFoundation

public struct DisassemblyResult {
    public enum Element {
        case label(String)
        case instruction(address: Int, raw: [u8], value: String)
    }
    
    public private(set) var elements: [Element]
}
