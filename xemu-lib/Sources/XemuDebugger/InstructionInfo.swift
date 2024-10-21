public struct InstructionInfo: CustomStringConvertible {
    public let address: Int
    public let values: [UInt8]
    public let mnemonic: String
    public let operands: String
    
    public init(
        address: Int,
        values: [UInt8],
        mnemonic: String,
        operands: String
    ) {
        self.address = address
        self.values = values
        self.mnemonic = mnemonic
        self.operands = operands
    }
    
    public var description: String {
        let values = values
            .map { $0.hex(prefix: "", padTo: 2, uppercase: true) }
            .joined(separator: " ")
        
        return [
            address.hex(prefix: "", padTo: 4, uppercase: true),
            
            values
                .padding(toLength: 8, withPad: " ", startingAt: 0),
            
            "\(mnemonic.uppercased()) \(operands.uppercased())"
                .padding(toLength: 31, withPad: " ", startingAt: 0)
        ]
        .joined(separator: "  ")
    }
}
