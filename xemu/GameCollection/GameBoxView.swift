import SwiftUI
import XemuPersistance

struct GameBoxView: View {
    @Environment(\.modelContext) var modelContext
    
    private var game: Game
    @State private var name: String
    @State private var artworkURL: URL? = nil
    @State private var renameOpen: Bool = false
    @State private var changeArtworkOpen: Bool = false
    @State private var gameDatabaseOpen: Bool = false
    @State private var deleteOpen: Bool = false
    
    init(game: Game) {
        self.game = game
        _name = State(initialValue: game.name)
    }
    
    var body: some View {
        VStack(spacing: .s) {
            if let artwork = game.artwork {
                Image(data: artwork)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(maxWidth: 100, maxHeight: 100)
            } else {
                GamePlaceholder(console: game.console)
                    .frame(width: 100, height: 100)
            }
            
            Text(game.name)
                .textStyle(.code(.s))
                .lineSpacing(.xxs)
        }
        .frame(width: 100)
        .padding(.xs)
        .contentShape(RoundedRectangle(cornerRadius: .xs))
        .contextMenu {
            RenameButton()
            
            Button("Change Artwork", systemImage: "photo") {
                changeArtworkOpen = true
            }
            
//            ShareLink(items: [game.data])
            
#if DEBUG
            Divider()
            
            Button("Copy MD5 Hash", systemImage: "clipboard") {
#if canImport(UIKit)
                UIPasteboard.general.string = game.id.uppercased()
                
#elseif canImport(AppKit)
                let pasteboard = NSPasteboard.general
                pasteboard.clearContents()
                pasteboard.setString(game.id.uppercased(), forType: .string)
#endif
            }
#endif
            
            Divider()

            Button("Delete", systemImage: "trash", role: .destructive) {
                deleteOpen = true
            }
        }
        .renameAction {
            renameOpen = true
        }
        .confirmationDialog("Change Artwork", isPresented: $changeArtworkOpen) {
#if canImport(UIKit)
            if UIPasteboard.general.hasImages {
                Button("Clipboard") {
                    if let image = UIPasteboard.general.image, let data = image.jpegData(compressionQuality: 1.0) {
                        game.artwork = data
                    }
                    changeArtworkOpen = false
                }
            }
#elseif canImport(AppKit)
            Button("Clipboard") {
                if let data = NSPasteboard.general.data(forType: .png) {
                    game.artwork = data
                }
                changeArtworkOpen = false
            }
#endif

            Button("Game Database") {
                gameDatabaseOpen = true
            }
            
            Divider()
            
            if game.artwork != nil {
                Button("Delete", role: .destructive) {
                    game.artwork = nil
                    changeArtworkOpen = false
                }
            }
            
            Divider()

            Button("Cancel", role: .cancel) {
                changeArtworkOpen = false
            }
        }
        .sheet(isPresented: $gameDatabaseOpen) {
            GameDatabaseReleasesView(game: game)
        }
        .alert("Rename Game", isPresented: $renameOpen) {
            TextField("Name", text: $name)
            
            Button("Cancel", role: .cancel) {
                renameOpen = false
            }
            
            Button("Rename") {
                game.name = name
                renameOpen = false
            }
        }
        .alert(
            "Are you sure you want to delete this game?",
            isPresented: $deleteOpen,
            actions: {
                Button("Cancel", role: .cancel) {
                    deleteOpen = false
                }
                
                Button("Delete", role: .destructive) {
                    deleteOpen = false
                    modelContext.delete(game)
                }
            },
            message: {
                Text("All associated data, such as saves and save states, will also be deleted.")
            }
        )
    }
}

#Preview {
    GameBoxView(
        game: Game(
            identifier: .init("0"),
            name: "The Legend of Zelda",
            data: .init(),
            console: .nes
        )
    )
}
