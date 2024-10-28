import SwiftUI
import XemuCore

struct GameView: View {
    let game: Game
    
    var body: some View {
        ZStack(alignment: .top) {
            Rectangle()
                .fill(.backgroundInverse)
                .ignoresSafeArea()
            
            NESView(game.data)
                .ignoresSafeArea(edges: .bottom)
        }
    }
}
