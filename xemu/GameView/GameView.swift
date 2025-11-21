import SwiftUI
import XemuCore
import XemuNES

struct GameView: View {
    @Environment(AppContext.self) var context
    @Environment(\.horizontalSizeClass) var horizontalSizeClass

    @State var isRunning: Bool = true
    @State var input: NESInput = .init()
    
    let emulator: Emulator?
    let game: Game
    
    init(game: Game) {
        self.game = game
        
        switch game.system {
            case .nes:
                self.emulator = NES()
            default:
                self.emulator = nil
        }
    }
    
    var body: some View {
        if let emulator {
            ZStack(alignment: .top) {
                Rectangle()
                    .fill(.backgroundInverse)
                    .backgroundExtensionEffect()
                
                VStack(spacing: .zero) {
                    switch game.system {
                        case .nes:
                            createNesView(emulator: emulator as! NES)
                        default:
                            Color.red
                    }
                }
            }
            .environment(input)
        } else {
            EmptyView()
                .onAppear {
                    context.set(state: .menu)
                    context.error = .notImplemented
                }
        }
    }
    
    @ViewBuilder
    private func createNesView(emulator: NES) -> some View {
        VStack(spacing: .zero) {
            ZStack(alignment: .bottom) {
                NESView(
                    isRunning: $isRunning,
                    nes: emulator,
                    game: game.data,
                    palette: .default
                )
    #if os(tvOS)
                .ignoresSafeArea(edges: .top)
    #endif
                
//                if !isRunning {
//                    createPauseOverlay()
//                }
                
    #if os(iOS)
                if horizontalSizeClass == .regular {
                    NesOverlayInputView()
                }
    #endif
            }

    #if os(iOS)
            if horizontalSizeClass == .compact {
                NesInputView(onMenu: {
                    isRunning = false
                })
            }
    #endif
        }
        .ignoresSafeArea()
        .sheet(isPresented: Binding(
            get: {
                !isRunning
            },
            set: {
                isRunning = !$0
            }
        )) {
            GameMenuView(
                isRunning: $isRunning,
                name: game.name,
                emulator: emulator
            )
        }
    }
    
    @ViewBuilder
    private func createPauseOverlay() -> some View {
        Button(action: {
            isRunning = true
        }, label: {
            Rectangle()
                .fill(.ultraThinMaterial)
                .ignoresSafeArea()
                .overlay {
                    VStack(spacing: .s) {
                        Image(systemName: "pause.circle.fill")
                            .font(.system(size: .xxxl, weight: .bold))
                        
                        Text("Paused")
                            .retroTextStyle(size: .xl, weight: .bold)
                    }
                }
                .transition(.opacity)
        })
    }
}
