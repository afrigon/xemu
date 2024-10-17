import SwiftUI

struct GameImporterModifier: ViewModifier {
    let isPresented: Binding<Bool>
    let onCompletion: (Result<[URL], Error>) -> Void
    
    func body(content: Content) -> some View {
        content
#if os(tvOS)
//            .gameUploadGameServer(
//                isPresented: isPresented,
//                onCompletion: onCompletion
//            )
//          TODO: spawn a webserver with a file upload route
//          TODO: generate and present a QR Code to let the person access the web server
            .webServer(
                isPresented: isPresented,
                onCompletion: onCompletion
            )
#else
            .fileImporter(
                isPresented: isPresented,
                allowedContentTypes: [.data], // TODO: only allow supported types, and no directory
                allowsMultipleSelection: true,
                onCompletion: onCompletion
            )
#endif
    }
}

extension View {
    func gameImporter(isPresented: Binding<Bool>, onCompletion: @escaping (Result<[URL], any Error>) -> Void) -> some View {
        modifier(GameImporterModifier(isPresented: isPresented, onCompletion: onCompletion))
    }
}
