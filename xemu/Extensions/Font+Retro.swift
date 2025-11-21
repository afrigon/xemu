import SwiftUI
import stylx

enum RetroFontSize {
    case xl
    case l
    case m
    case s
    case xs
    
    var value: CGFloat {
        return switch self {
            case .xl:
                .init(19, tvOS: 38)
            case .l:
                .init(16, tvOS: 32)
            case .m:
                .init(14, tvOS: 28)
            case .s:
                .init(12, tvOS: 24)
            case .xs:
                .init(10, tvOS: 20)
        }
    }
    
    var lineSpacing: CGFloat {
        return switch self {
            case .xs:
                .xxs
            default:
                1
        }
    }
}

extension Font {
    static func retro(size: RetroFontSize, weight: Font.Weight = .regular) -> Font {
        .monaspace(size: size.value, weight: weight)
    }
}

extension View {
    func retroTextStyle(size: RetroFontSize, weight: Font.Weight = .regular) -> some View {
        self
            .font(.retro(size: size, weight: weight))
            .lineSpacing(size.lineSpacing)
    }
}

#Preview {
    VStack {
        Text("The quick brown fox jumps over the lazy dog")
            .retroTextStyle(size: .xl, weight: .bold)
        Text("The quick brown fox jumps over the lazy dog")
            .retroTextStyle(size: .l, weight: .bold)
        Text("The quick brown fox jumps over the lazy dog")
            .retroTextStyle(size: .m, weight: .bold)
        Text("The quick brown fox jumps over the lazy dog")
            .retroTextStyle(size: .xs, weight: .bold)
        
        Text("The quick brown fox jumps over the lazy dog")
            .retroTextStyle(size: .xl)
        Text("The quick brown fox jumps over the lazy dog")
            .retroTextStyle(size: .l)
        Text("The quick brown fox jumps over the lazy dog")
            .retroTextStyle(size: .m)
        Text("The quick brown fox jumps over the lazy dog")
            .retroTextStyle(size: .xs)
    }
}
