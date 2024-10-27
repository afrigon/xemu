import SwiftUI
import XemuCore

struct GameView: View {
    let game: Game
    
    var body: some View {
        ZStack {
            Rectangle()
                .fill(.backgroundInverse)
                .ignoresSafeArea()
            
            NESView(game.data)
        }
    }
}
