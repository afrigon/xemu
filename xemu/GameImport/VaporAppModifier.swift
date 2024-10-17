import SwiftUI
import Vapor

struct VaporAppModifier: ViewModifier {
    let isPresented: Binding<Bool>
    let app: Binding<Application>

    func body(content: Self.Content) -> some SwiftUI.View {
        if isPresented.wrappedValue {
            content
                .onAppear {
                    do {
                        try app.wrappedValue.start()
                    } catch {
                        isPresented.wrappedValue = false
                    }
                }
                .onDisappear {
                    app.wrappedValue.shutdown()
                }
        }
    }
}

extension SwiftUI.View {
    func vaporApp(
        isPresented: Binding<Bool>,
        app: Binding<Application>
    ) -> some SwiftUI.View {
        modifier(VaporAppModifier(isPresented: isPresented, app: app))
    }
}
