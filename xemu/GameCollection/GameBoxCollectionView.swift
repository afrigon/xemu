import SwiftUI
import SwiftData
import XemuCore

struct GameBoxCollectionView: View {
    @AppStorage(.gameCollectionSorting) private var gameCollectionSorting: GameCollectionSorting = .lastPlayed

    @Query private var games: [Game]
    
    private var system: SystemType

    private var importOpen: Binding<Bool>?
    
    init(system: SystemType, importOpen: Binding<Bool>? = nil) {
        self.system = system
        self.importOpen = importOpen

        _games = Query(
            filter: #Predicate<Game> {
                $0._system == system.rawValue
            }
        )
    }
    
    var body: some View {
        let columns = [
            GridItem(.adaptive(minimum: .xxxxxxl), spacing: .xs, alignment: .bottom)
        ]
        
        ScrollView {
            LazyVGrid(columns: columns, spacing: .xs) {
                let sortedGames = games.sorted { l, r in
                    switch gameCollectionSorting {
                        case .lastPlayed:
                            if l.lastPlayedDate == r.lastPlayedDate {
                                return l.name < r.name
                            }
                            
                            if let ldate = l.lastPlayedDate, let rdate = r.lastPlayedDate {
                                return ldate > rdate
                            } else {
                                return l.lastPlayedDate != nil
                            }
                        case .name:
                            return l.name < r.name
                    }
                }
                
                ForEach(sortedGames) { game in
                    GameBoxView(game: game)
                }
            }
            .padding(.m)
        }
        .overlay {
            if games.isEmpty {
                ContentUnavailableView(label: {
                    Image(system.icon)
                        .resizable()
                        .frame(width: .init(.xxxxxl, tvOS: .xxxxxxxl), height: .init(.xxxxxl, tvOS: .xxxxxxxl))
                    Text("No Games")
                        .retroTextStyle(size: .header, weight: .bold)
                        .padding(.s)
                }, description: {
                    Text("Your collection is empty. Import games with the + button to start playing.")
                        .retroTextStyle(size: .subtitle)
                }, actions: {
                    if let importOpen {
                        Button("Import Games") {
                            importOpen.wrappedValue = true
                        }
                        .loading(importOpen.wrappedValue)
                        .environment(\.colorRole, .primary)
                        .buttonStyle(.retro(scale: .m, format: .regular))
                    }
                })
            }
        }
        .background(.ultraThinMaterial)
    }
}

#Preview("Empty") {
    GameBoxCollectionView(system: .nes)
        .mockContext()
}

#Preview {
    GameBoxCollectionView(system: .nes)
        .mockData(for: Game.self) {
            let createData = { (name: String, system: SystemType, artwork: ImageResource?) -> Game in
                let game = Game(
                    identifier: .init(from: name.data(using: .utf8)!),
                    name: name,
                    data: .init(),
                    system: system
                )
                
                if let artwork {
                    game.artwork = Data(image: artwork)
                }
                
                return game
            }
                
            return [
                createData("The Legend of Zelda", .nes, .nesArtworkFront),
                createData("The Legend of Zelda: Ocarina of Time", .nes, .n64ArtworkFront),
            ]
        }
        .mockContext()
}
