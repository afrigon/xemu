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
                    NESView(game: game.data, palette: .default)
                        .ignoresSafeArea(edges: .bottom)
#if os(tvOS)
                        .ignoresSafeArea(edges: .top)
#endif
                default:
                    Color.red
            }
        }
        .environment(input)
    }
}
