import SwiftUI
import XKit
import XemuCore
import stylx

struct MainView: View {
    @Environment(\.modelContext) var modelContext
    
    @State private var context: AppContext = .init()
    @State private var showDebugDefaultsView: Bool = false

    var body: some View {
        VStack {
            switch context.state {
                case .loading:
                    LoadingView()
                        .task {
                            await context.setup()
                        }
                case .error(let error):
                    ErrorView(error: error)
                case .menu:
                    MenuView()
                case .gaming(let game):
                    GameView(game: game)
            }
        }
        .alert(
            "Error",
            isPresented: .constant(context.error != nil),
            actions: {
                Button("OK") {
                    context.error = nil
                }
            }, message: {
                if let error = context.error?.message {
                    Text(error)
                }
            })
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(.backgroundDefault)
        .onOpenURL { url in
            do throws(XemuError) {
                let game = try ImportExportService.shared.importGame(url)
                modelContext.insert(game)
            } catch let error {
               context.error = error
            }
        }
#if DEBUG
        .gesture(
            TapGesture(count: 4)
                .onEnded { _ in showDebugDefaultsView = true }
        )
        .sheet(isPresented: $showDebugDefaultsView) {
            NavigationStack {
                DebugDefaultsView()
                    .toolbar {
                        ToolbarItem(placement: .confirmationAction) {
                            Button("Done") {
                                showDebugDefaultsView = false
                            }
                        }
                    }
            }
        }
#endif // if DEBUG
        .environment(context)
        .environment(\.error, ErrorAction(handler: { error in
            context.set(state: .error(error))
            return .handled
        }))
    }
}

#Preview {
    MainView()
}
