public protocol AsmConvertible {
    func asm(offset: Int) -> String
}
