import SwiftUI

struct WebServerModifier: ViewModifier {
    let isPresented: Binding<Bool>
    let onCompletion: (Result<[URL], Error>) -> Void
    
    func body(content: Content) -> some View {
        content
    }
}

extension View {
    func webServer(isPresented: Binding<Bool>, onCompletion: @escaping (Result<[URL], any Error>) -> Void) -> some View {
        modifier(WebServerModifier(isPresented: isPresented, onCompletion: onCompletion))
    }
}
