import XemuNES
import SwiftUI
import XemuCore
import XemuFoundation
import stylx

public struct NESView: View {
    @Environment(AppContext.self) var context
    @Environment(NESInput.self) var input

    @State var paused: Bool = true
    @State var frame: CGImage? = nil
    @FocusState private var isFocused: Bool
    
    @State var fps: Int = 60
    @State var currentTime: Double = CACurrentMediaTime()
    @State var cycleBudget: Int = 0

    let game: Data
    let nes: NES

    public init(_ game: Data) {
        self.game = game
        nes = .init()
    }
    
    public var body: some View {
        ZStack(alignment: .topTrailing) {
            if let frame {
                Image(platformImage: .init(cgImage: frame, size: .init(width: 256, height: 240)))
                    .resizable()
                    .interpolation(.none)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                Palette.default.color(for: 0)
            }
            
            Text(verbatim: "\(fps)")
                .foregroundStyle(.white)
                .retroTextStyle(size: .header)
                .shadow(color: .black, radius: 0.1, x: -1, y:  0)
                .shadow(color: .black, radius: 0.1, x:  1, y:  0)
                .shadow(color: .black, radius: 0.1, x:  0, y:  1)
                .shadow(color: .black, radius: 0.1, x:  0, y: -1)
                .padding(.m)
        }
        .onAppear {
            do throws(XemuError) {
                try nes.load(program: game)
                nes.reset()
                paused = false
                isFocused = true
            } catch let error {
                paused = true
                context.error = error
                context.set(state: .menu)
            }
        }
        .focusable()
        .focused($isFocused)
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
                case "m": fn(.start)
                case "n": fn(.select)
                case "p": fn(.b)
                case "o": fn(.a)
                default:
                    return .ignored
            }
            
            return .handled
        }
        .loop(fps: 60) { delta in
            guard !paused else {
                return
            }
            
            if cycleBudget != 0 {
                return
            }
            
            nes.controller1.input = input.encode()

            cycleBudget = Int(delta * 1789773)
            
            do {
                for _ in 0..<cycleBudget {
                    try nes.clock()
                }
                
                cycleBudget = 0
            } catch let error {
                // TODO: do something with nes crash
                print(error)
            }
            
            let newCurrentTime = CACurrentMediaTime()
            fps = Int((1 / (newCurrentTime - currentTime)).rounded())
            currentTime = newCurrentTime

            draw()
        }
        .aspectRatio(256 / 240, contentMode: .fit)
    }
    
    private func draw() {
        guard let data = nes.frame else {
            return
        }
        
        guard let colorSpace = Palette.default.colorSpace,
              let provider = CGDataProvider(data: data as CFData) else {
            return
        }
            
        frame = CGImage(
            width: 256,
            height: 240,
            bitsPerComponent: 8,
            bitsPerPixel: 8,
            bytesPerRow: 256,
            space: colorSpace,
            bitmapInfo: CGBitmapInfo(rawValue: CGImageAlphaInfo.none.rawValue),
            provider: provider,
            decode: nil,
            shouldInterpolate: false,
            intent: .defaultIntent
        )
    }
}

#Preview {
    NESView(Data())
}
