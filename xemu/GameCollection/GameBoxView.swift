import SwiftUI
import stylx
import XemuCore

struct GameBoxView: View {
    @Environment(AppContext.self) var context
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
        Button(action: {
            game.lastPlayedDate = Date()
            context.set(state: .gaming(game))
        }, label: {
            VStack(spacing: .s) {
                if let artwork = game.artwork, let image = PlatformImage(data: artwork) {
                    ImageThatFits(artwork, maxSize: .xxxxxxxl)
                        .clipShape(RoundedRectangle(cornerRadius: .xxs))
                } else {
                    GamePlaceholder(system: game.system)
                        .frame(width: .xxxxxxxl, height: .xxxxxxxl)
                }
                
                Text(verbatim: game.name)
                    .retroTextStyle(size: .body)
                    .foregroundStyle(.foregroundDefault)
                    .lineLimit(4)
            }
        })
        .frame(maxWidth: .xxxxxxxl)
        .padding(.xs)
        .contentShape(RoundedRectangle(cornerRadius: .xs))
        .contextMenu {
            Text(verbatim: game.name)
            
            RenameButton()
            
            Button("Change Artwork", systemImage: "photo") {
                changeArtworkOpen = true
            }
            
//            ShareLink(items: [game.data])
            
#if DEBUG
            if ClipboardService.canUseClipboard {
                Divider()
                
                Button("Copy MD5 Hash", systemImage: "clipboard") {
                    ClipboardService.shared.copy(game.id.uppercased())
                }
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
#if canImport(UIKit) && !os(tvOS)
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
    let zelda = Game(
        identifier: .init("0"),
        name: "The Legend of Zelda",
        data: .init(),
        system: .nes
    )
    zelda.artwork = .init(image: .nesArtworkFront)
    
    let oot = Game(
        identifier: .init("1"),
        name: "The Legend of Zelda: Ocarina of Time",
        data: .init(),
        system: .nintendo64
    )
    oot.artwork = .init(image: .n64ArtworkFront)

    return VStack {
        HStack {
            GameBoxView(
                game: Game(
                    identifier: .init("2"),
                    name: "The Legend of Zelda",
                    data: .init(),
                    system: .nes
                )
            )
            
            GameBoxView(game: zelda)
        }
        
        HStack {
            GameBoxView(
                game: Game(
                    identifier: .init("3"),
                    name: "The Legend of Zelda: Ocarina of Time",
                    data: .init(),
                    system: .nintendo64
                )
            )
            
            GameBoxView(game: oot)
        }
    }
}
