import SwiftUI

struct GameImporterModifier: ViewModifier {
    @Environment(\.modelContext) var modelContext
    
    let isPresented: Binding<Bool>
    let onCompletion: (Result<[URL], Error>) -> Void
    
    func body(content: Content) -> some View {
        content
#if os(tvOS)
            .sheet(isPresented: isPresented) {
                GameUploadServerView(isPresented: isPresented) { @MainActor title, data in
                    do {
                        let game = try ImportExportService.shared.importGame(title, data: data)
                        modelContext.insert(game)
                    } catch {
                        return false
                    }
                    
                    return true
                }
            }
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
