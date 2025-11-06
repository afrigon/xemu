extension Bool {
    @inline(__always) public init<T: BinaryInteger>(_ value: T) {
        self = value != 0
    }
}
