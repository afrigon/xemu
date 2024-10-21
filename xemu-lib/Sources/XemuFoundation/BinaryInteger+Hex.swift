extension BinaryInteger {
    public func hex(prefix: String, padTo width: Int, uppercase: Bool = false) -> String {
        let value = String(self, radix: 16, uppercase: uppercase)
        let padCount = max(0, width - value.count)
        let pad = String(repeating: "0", count: padCount)
        return prefix + pad + value
    }
}
