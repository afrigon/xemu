extension Bool {
    public init<T: BinaryInteger>(_ value: T) {
        self = value != 0
    }
}
