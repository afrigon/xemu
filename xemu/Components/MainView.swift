import SwiftUI
import XKit
import XemuPersistance
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
                case .ready:
                    ReadyView()
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
            let fileExtension = url.pathExtension.lowercased()
            let supportedExtensions: [String] = ["nes"]
            
            guard supportedExtensions.contains(fileExtension) else {
                return context.error = .unsuportedFileExtension
            }
            
            guard url.startAccessingSecurityScopedResource() else {
                return context.error = .fileSystemError
            }
            
            defer { url.stopAccessingSecurityScopedResource() }
            
            guard let data = try? Data(contentsOf: url) else {
                return context.error = .fileSystemError
            }
            
            switch fileExtension {
                case "nes":
                    handleGame(url: url, data, console: .nes)
                case "smc", "sfc", "fig":
                    handleGame(url: url, data, console: .snes)
                case "gb":
                    handleGame(url: url, data, console: .gb)
                case "gbc":
                    handleGame(url: url, data, console: .gbc)
                case "gba":
                    handleGame(url: url, data, console: .gba)
                case "ds", "nds":
                    handleGame(url: url, data, console: .ds)
                case "n64", "z64":
                    handleGame(url: url, data, console: .n64)
                default:
                    return
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
                    .modify { view in
#if os(macOS)
                        view
                            .padding(.l)
                            .toolbar {
                                ToolbarItem(placement: .confirmationAction) {
                                    Button("Done") { showDebugDefaultsView = false }
                                }
                            }
#else
                        view
                            .toolbar {
                                ToolbarItem(placement: .topBarTrailing) {
                                    Button("Done") { showDebugDefaultsView = false }
                                }
                            }
                            .navigationBarTitleDisplayMode(.inline)
#endif // if macOS
                    }
            }
        }
#endif // if DEBUG
        .environment(context)
    }
    
    private func handleGame(url: URL, _ data: Data, console: ConsoleType) {
        let filename = url.deletingPathExtension().lastPathComponent
        let identifier = XemuIdentifier(from: data)
        
        let game = Game(
            identifier: identifier,
            name: filename,
            data: data,
            console: console
        )
        
        modelContext.insert(game)
        tryFetchArtwork(url, for: game)
    }
    
    private func tryFetchArtwork(_ url: URL, for game: Game) {
        guard let service = OpenVGDBService.shared else {
            return
        }
        
        let cleanedFileName = game.name
            .replacing(/\(.*\)/, with: "")
            .replacing(/\[.*\]/, with: "")
            .replacing(/-\d+$/, with: "")
            .replacing(/'s/, with: "")
            .replacing(/,/, with: "")
            .replacing(/\ \d+\ /, with: " ")
            .replacing(/-/, with: "")
            .replacing(/\s+/, with: " ")
            .trimmingCharacters(in: .whitespacesAndNewlines)
        
        let releases = service.getReleases(like: cleanedFileName, for: game.console.openVGDBIdentifier)
        
        guard let url = releases.first?.artworkURL else {
            return
        }
            
        Task {
            guard let artwork = await url.data() else {
                return
            }
            
            game.artwork = artwork
        }
    }
}

#Preview {
    MainView()
}
