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
                    saveData: game.save?.data,
                    palette: .default
                )
    #if os(tvOS)
                .ignoresSafeArea(edges: .top)
    #endif
                
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
        .onChange(of: isRunning) {
            // only save when pausing, triggered when going to menu or sending the app to background
            guard !isRunning else {
                return
            }
            
            guard let saveData = emulator.saveData, !saveData.isEmpty else {
                return
            }
            
            if let save = game.save {
                save.data = Data(saveData)
                save.screenshot = Data(emulator.frameBuffer)
            } else {
                let save = GameSave(
                    game: game,
                    data: Data(saveData),
                    screenshot: Data(emulator.frameBuffer)
                )
                
                game.saves.append(save)
                game.currentSave = save.id
            }
        }
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
                emulator: emulator,
                game: game
            )
        }
    }
}
