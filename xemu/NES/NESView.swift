import XemuNES
import SwiftUI
import XemuCore
import XemuFoundation
import stylx

public struct NESView: View {
    @Environment(AppContext.self) var context

    @State var paused: Bool = true
    @State var frame: CGImage? = nil
    @State var fps: Int = 60

    let game: Data
    let nes: NES

    public init(_ game: Data) {
        self.game = game
        nes = .init()
    }
    
    public var body: some View {
        ZStack(alignment: .topTrailing) {
            if let frame {
                Image(platformImage: .init(cgImage: frame))
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
            } catch let error {
                paused = true
                context.error = error
                context.set(state: .menu)
            }
        }
        .loop { delta in
            guard !paused else {
                return
            }
            
            let cycles = Int(delta * 1789773)
            
            do {
                for _ in 0..<cycles {
                    try nes.clock()
                }
            } catch let error {
                // TODO: do something with nes crash
                print(error)
            }
            
            fps = Int((1 / delta).rounded())
            
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
