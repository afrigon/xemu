extension BinaryInteger {
    public func hex(
        prefix: String = "",
        toLength length: Int = 0,
        textCase: TextCase = .lowercase
    ) -> String {
        let value = String(self, radix: 16, uppercase: textCase == .uppercase)
        let count = max(0, length - value.count)
        let pad = String(repeating: "0", count: count)
        return prefix + pad + value
    }
}
