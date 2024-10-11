import SwiftUI
import SwiftData
import XemuPersistance
import XemuCore

struct GameBoxCollectionView: View {
    @Environment(AppContext.self) var context

    @Query var games: [Game]
    
    private var console: ConsoleType
    
    init(console: ConsoleType) {
        self.console = console
        
        _games = Query(filter: #Predicate<Game> {
            $0._console == console.rawValue
        })
    }
    
    var body: some View {
        let columns = [
            GridItem(.adaptive(minimum: 100), alignment: .top)
        ]
        
        return ScrollView {
            LazyVGrid(columns: columns) {
                ForEach(games) { game in
                    GameBoxView(game: game)
                }
            }
            .padding(.m)
        }
    }
}

#Preview {
    GameBoxCollectionView(console: .nes)
}
