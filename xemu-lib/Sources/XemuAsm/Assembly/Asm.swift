//public struct Asm: CustomStringConvertible {
//    private(set) var elements: [AsmElement]
//    
//    public init(@AsmBuilder _ builder: () -> [AsmElement]) {
//        elements = builder()
//    }
//    
//    public var description: String {
//        elements
//            .map(\.description)
//            .joined(separator: "\n")
//    }
//}
