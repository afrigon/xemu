import XemuFoundation

public struct DisassemblyResult<T> {
    public struct Element {
        public let address: Int
        public let raw: [u8]
        public let value: T
    }
    
    public private(set) var elements: [Element]
}
