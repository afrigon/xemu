import SwiftUI
import XemuCore

struct GameView: View {
    @Environment(AppContext.self) var context
    
    @State var input: NESInput = .init()
    
    let game: Game
    
    var body: some View {
        ZStack(alignment: .top) {
            Rectangle()
                .fill(.backgroundInverse)
                .ignoresSafeArea()
            
            VStack {
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
                
                Button(action: {
                    context.set(state: .menu)
                }, label: {
                    Text("Menu")
                })
            }
        }
        .environment(input)
    }
}
