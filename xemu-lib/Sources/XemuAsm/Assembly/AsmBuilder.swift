//@resultBuilder
//public struct AsmBuilder {
//    public static func buildPartialBlock(first: AsmElement...) -> [AsmElement] {
//        first
//    }
//    
//    public static func buildPartialBlock(accumulated: [AsmElement], next: AsmElement...) -> [AsmElement] {
//        accumulated + next
//    }
//    
//    public static func buildPartialBlock(first: [AsmElement]...) -> [AsmElement] {
//        first.flatMap { $0 }
//    }
//    
//    public static func buildPartialBlock(accumulated: [AsmElement], next: [AsmElement]...) -> [AsmElement] {
//        accumulated + next.flatMap { $0 }
//    }
//    
//    public static func buildPartialBlock(first: AsmElementConvertible...) -> [AsmElement] {
//        first.map(\.asmElement)
//    }
//    
//    public static func buildPartialBlock(accumulated: [AsmElement], next: AsmElementConvertible...) -> [AsmElement] {
//        accumulated + next.map(\.asmElement)
//    }
//    
//    public static func buildOptional(_ component: [AsmElement]?) -> [AsmElement] {
//        component ?? []
//    }
//    
//    public static func buildEither(first component: [AsmElement]) -> [AsmElement] {
//        component
//    }
//    
//    public static func buildEither(second component: [AsmElement]) -> [AsmElement] {
//        component
//    }
//}
