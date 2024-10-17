extension Array where Element == UInt8 {
    subscript (_ index: UInt16) -> Element {
        get {
            self[Int(index)]
        }
        set {
            self[Int(index)] = newValue
        }
    }
}
