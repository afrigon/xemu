import SwiftUI
import stylx

extension ButtonStyle where Self == RetroButtonStyle {
    public static func retro(
        scale: ButtonScale,
        format: ButtonFormat
    ) -> RetroButtonStyle {
        RetroButtonStyle(scale: scale, format: format)
    }
}

public struct RetroButtonStyle: ButtonStyle {
    @Environment(\.isEnabled) private var isEnabled
    @Environment(\.isLoading) private var isLoading
    @Environment(\.colorScheme) private var colorScheme

    let scale: ButtonScale
    let format: ButtonFormat

    public init(scale: ButtonScale = .m, format: ButtonFormat = .regular) {
        self.scale = scale
        self.format = format
    }
    
    public func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .lineLimit(1)
            .retroTextStyle(size: .m, weight: .bold)
            .padding(.vertical, scale.verticalPadding)
            .padding(.horizontal, format == .regular || format == .capsule ? scale.horizontalPadding : scale.verticalPadding)
            .modify(if: isLoading) { $0.foregroundStyle(.clear) }
            .modify { view in
                if isEnabled {
                    view
                        .foregroundStyle(.foregroundDefault)
                }
                else {
                    view
                        .foregroundStyle(.foregroundDisabled)
                }
            }
            .modify { view in
                if isEnabled {
                    view.background {
                        format.clipShape
                            .fill(.roleMuted)
                            .shadow(color: colorScheme == .light ? .black : .white, radius: 0, y: configuration.isPressed ? 1.5 : 3)
                    }
                }
                else {
                    view.background {
                        format.clipShape
                            .fill(.backgroundDisabled)
                            .shadow(color: colorScheme == .light ? .black : .white, radius: 0, y: configuration.isPressed ? 1.5 : 3)
                    }
                }
            }
            .contentShape(format.clipShape)
            .overlay {
                RoundedRectangle(cornerRadius: .xxs)
                    .strokeBorder(colorScheme == .light ? .black : .white)
            }
            .contentShape(format.clipShape)
            .opacity(configuration.isPressed ? 0.8 : 1)
            .offset(y: configuration.isPressed ? 1.5 : 0)
            .modify(if: isLoading) { view in
                view.overlay {
                    ProgressView()
                        .tint(ForegroundShapeStyle.foregroundDisabled)
#if !os(tvOS)
                        .controlSize(scale.progressSize)
#endif
                }
            }
    }
}

#Preview("Neutral") {
    Button(action: { }, label: {
        Text("Hello, World!")
    })
    .buttonStyle(.retro(scale: .s, format: .regular))
    .environment(\.colorRole, .primary)
}
