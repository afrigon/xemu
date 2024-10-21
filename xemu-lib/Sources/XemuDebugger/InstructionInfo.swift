public struct InstructionInfo {
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
}
