import SwiftUI
import XemuFoundation
import XemuCore
import XemuNES

struct NESView: View {
    @Environment(AppContext.self) var context
    @Environment(NESInput.self) var input
    @Environment(\.scenePhase) var scenePhase
    
    private let game: Data
    private let palette: [SIMD3<Float>]
    private let nes: NES
    private let audio: AudioService?

    @State private var isRunning = true
    @State private var fps: Int = 60
    @FocusState private var focused: Bool

    init(game: Data, palette: Palette) {
        self.game = game
        self.palette = stride(from: 0, to: palette.data.count, by: 3)
            .map {
                SIMD3(
                    Float(palette.data[$0]) / 255,
                    Float(palette.data[$0 + 1]) / 255,
                    Float(palette.data[$0 + 2]) / 255
                )
            }
        self.nes = .init()
        self.audio = .init()
    }
    
    var body: some View {
        ZStack(alignment: .topTrailing) {
            EmulatorIndexedRenderView($isRunning, nes, palette) { delta in
                update(delta)
                
                if delta > 0 {
                    fps = Int((1 / delta).rounded())
                }
            }
            .onTapGesture {
                isRunning.toggle()
            }
                
            Group {
                VStack(spacing: 8) {
                    Text(verbatim: "\(fps)")
                }
                .padding(.m)
            }
            .foregroundStyle(.white)
            .retroTextStyle(size: .header)
            .shadow(color: .black, radius: 0.1, x: -1, y:  0)
            .shadow(color: .black, radius: 0.1, x:  1, y:  0)
            .shadow(color: .black, radius: 0.1, x:  0, y:  1)
            .shadow(color: .black, radius: 0.1, x:  0, y: -1)
        }
        .onAppear {
            do throws(XemuError) {
                try nes.load(program: game)
                nes.reset()
                focused = true
                isRunning = true
            } catch let error {
                isRunning = false
                context.error = error
                context.set(state: .menu)
            }
        }
        .onDisappear {
            audio?.stop()
            isRunning = false
        }
        .onChange(of: isRunning) {
            if isRunning {
                audio?.start()
            } else {
                audio?.stop()
            }
        }
        .onChange(of: scenePhase) { oldPhase, newPhase in
            isRunning = newPhase == .active
        }
        .focusable()
        .focused($focused)
        .focusEffectDisabled()
        .onKeyPress(phases: [.up, .down]) { keyPress in
            let fn: ((NESInputKey) -> Void)? = switch keyPress.phase {
                case .up: input.keyUp
                case .down: input.keyDown
                default: nil
            }
            
            guard let fn else {
                return .ignored
            }
            
            switch keyPress.key {
                case "w": fn(.up)
                case "a": fn(.left)
                case "s": fn(.down)
                case "d": fn(.right)
                case "i": fn(.start)
                case "u": fn(.select)
                case "k": fn(.b)
                case "j": fn(.a)
                default:
                    return .ignored
            }
            
            return .handled
        }
    }
    
    private func update(_ delta: TimeInterval) {
        nes.controller1.input = input.encode()
        
        do {
            try nes.stepFrame()
        } catch let error {
            // TODO: do something with nes crash
            print(error)
            isRunning = false
            context.error = error
        }
        
        if let buffer = nes.audioBuffer {
            audio?.schedule(buffer)
        }
    }
}
