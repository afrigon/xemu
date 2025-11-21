import SwiftUI
import XemuFoundation
import XemuCore
import XemuNES

struct NESView: View {
    @AppStorage(.showFPS) var showFPS: Bool = false

    @Environment(AppContext.self) var context
    @Environment(NESInput.self) var input
    @Environment(\.scenePhase) var scenePhase
    
    private let game: Data
    private let palette: [SIMD3<Float>]
    private let nes: NES
    private let audio: AudioService?

    @Binding var isRunning: Bool
    @State private var fps: Int = 60
    @State private var backgroundColor: Color = .gray
    @FocusState private var focused: Bool

    init(
        isRunning: Binding<Bool>,
        nes: NES = .init(),
        game: Data,
        palette: Palette
    ) {
        self._isRunning = isRunning
        self.game = game
        self.palette = stride(from: 0, to: palette.data.count, by: 3)
            .map {
                SIMD3(
                    Float(palette.data[$0]) / 255,
                    Float(palette.data[$0 + 1]) / 255,
                    Float(palette.data[$0 + 2]) / 255
                )
            }
        self.nes = nes
        self.audio = .init()
    }
    
    var body: some View {
        ZStack(alignment: .center) {
            backgroundColor
                .backgroundExtensionEffect()
            
            ZStack(alignment: .top) {
                EmulatorIndexedRenderView($isRunning, nes, palette) { delta in
                    update(delta)
                    
                    if delta > 0 {
                        fps = Int((1 / delta).rounded())
                    }
                }
                .aspectRatio(nes.frameAspectRatio, contentMode: .fit)
                
                if showFPS {
                    HStack(spacing: .zero) {
                        VStack(spacing: 8) {
                            Text(verbatim: "\(fps)")
                        }
                        .padding(.m)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .foregroundStyle(.white)
                    .retroTextStyle(size: .xl)
                    .shadow(color: .black, radius: 0.1, x: -1, y:  0)
                    .shadow(color: .black, radius: 0.1, x:  1, y:  0)
                    .shadow(color: .black, radius: 0.1, x:  0, y:  1)
                    .shadow(color: .black, radius: 0.1, x:  0, y: -1)
                }
            }
        }
        .frame(maxHeight: .infinity, alignment: .center)
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
            if newPhase != .active {
                isRunning = false
            }
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
                case "j": fn(.b)
                case "k": fn(.a)
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
            isRunning = false
            context.error = error
            context.set(state: .menu)
        }
        
        if let buffer = nes.audioBuffer {
            audio?.schedule(buffer)
        }
        
        let color = palette[Int(nes.backgroundColor)]
        backgroundColor = Color(
            red: Double(color.x),
            green: Double(color.y),
            blue: Double(color.z)
        )
    }
}
