import SwiftUI
import stylx

struct StateButton<Label: View>: View{
    @Binding var isPressed: Bool
    let label: () -> Label
    
    var body: some View {
        GeometryReader { geometry in
            label()
                .frame(width: geometry.size.width, height: geometry.size.height)
                .contentShape(Rectangle())
                .gesture(
                    DragGesture(minimumDistance: 0)
                        .onChanged { value in
                            let isInside = value.location.x >= 0 && value.location.x <= geometry.size.width &&
                                           value.location.y >= 0 && value.location.y <= geometry.size.height
                            
                            if isInside && !isPressed {
                                HapticsService.shared.impact()
                                isPressed = true
                            } else if !isInside && isPressed {
                                HapticsService.shared.impact(intensity: 0.5)
                                isPressed = false
                            }
                        }
                        .onEnded { value in
                            if isPressed {
                                HapticsService.shared.impact(intensity: 0.5)
                                isPressed = false
                            }
                        }
                )
        }
    }
}

struct StateButtonStyle: ButtonStyle {
    @Binding var isPressed: Bool
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.96 : 1.0)
            .animation(.easeOut(duration: 0.2), value: configuration.isPressed)
            .onChange(of: configuration.isPressed) { _, newValue in
                isPressed = newValue
            }
    }
}
