import SwiftUI
import stylx

enum RetroFontSize {
    case header
    case title
    case subtitle
    case body
    
    var value: CGFloat {
        return switch self {
            case .header:
                .init(19, tvOS: 40)
            case .title:
                16
            case .subtitle:
                .init(14, tvOS: 28)
            case .body:
                10
        }
    }
    
    var lineSpacing: CGFloat {
        return switch self {
            case .body:
                .xxs
            default:
                1
        }
    }
}

extension Font {
    static func retro(size: RetroFontSize, weight: TextWeight = .regular) -> Font {
        .monaspace(size: size.value, weight: weight.value)
    }
}

extension View {
    func retroTextStyle(size: RetroFontSize, weight: TextWeight = .regular) -> some View {
        self
            .font(.retro(size: size, weight: weight))
            .lineSpacing(size.lineSpacing)
    }
}

#Preview {
    VStack {
        Text("The quick brown fox jumps over the lazy dog")
            .retroTextStyle(size: .header, weight: .bold)
        Text("The quick brown fox jumps over the lazy dog")
            .retroTextStyle(size: .title, weight: .bold)
        Text("The quick brown fox jumps over the lazy dog")
            .retroTextStyle(size: .subtitle, weight: .bold)
        Text("The quick brown fox jumps over the lazy dog")
            .retroTextStyle(size: .body, weight: .bold)
        
        Text("The quick brown fox jumps over the lazy dog")
            .retroTextStyle(size: .header)
        Text("The quick brown fox jumps over the lazy dog")
            .retroTextStyle(size: .title)
        Text("The quick brown fox jumps over the lazy dog")
            .retroTextStyle(size: .subtitle)
        Text("The quick brown fox jumps over the lazy dog")
            .retroTextStyle(size: .body)
    }
}
