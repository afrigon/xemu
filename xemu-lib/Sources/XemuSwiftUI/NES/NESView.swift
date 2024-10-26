import XemuNES
import SwiftUI
import XemuCore

public struct NESView: View {
    @State var paused: Bool = false
    
    let game: Data
    let nes: NES
    
    public init(_ game: Data) {
        self.game = game
        nes = .init()
    }
    
    public var body: some View {
        Text("Hello, World!")
            .onAppear {
                do {
                    try nes.load(program: game)
                    nes.reset()
                } catch {
                    // TODO: error message + return to menu
                }
            }
    }
}

#Preview {
    NESView(Data())
}
