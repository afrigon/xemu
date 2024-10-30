import SwiftUI
import XemuCore

struct GameView: View {
    @State var input: NESInput = .init()
    
    let game: Game
    
    var body: some View {
        ZStack(alignment: .top) {
            Rectangle()
                .fill(.backgroundInverse)
                .ignoresSafeArea()
            
            switch game.system {
                case .nes:
                    NESViewV2(game: game.data, palette: .default)
//                    NESView(game.data)
//                        .ignoresSafeArea(edges: .bottom)
                default:
                    Color.red
            }
        }
        .environment(input)
    }
}
