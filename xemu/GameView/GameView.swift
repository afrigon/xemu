import SwiftUI
import XemuCore

struct GameView: View {
    let game: Game
    
    var body: some View {
        ZStack {
            Rectangle()
                .fill(.backgroundInverse)
                .ignoresSafeArea()
            
            Color.blue
                .frame(width: 100, height: 100)
        }
    }
}
