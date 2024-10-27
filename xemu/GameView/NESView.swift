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

    let palette: [u8] = [
        0x62, 0x62, 0x62,
        0x00, 0x2c, 0x7c,
        0x11, 0x15, 0x9c,
        0x36, 0x03, 0x9c,
        0x55, 0x00, 0x7c,
        0x67, 0x00, 0x44,
        0x67, 0x07, 0x03,
        0x55, 0x1c, 0x00,
        0x36, 0x32, 0x00,
        0x11, 0x44, 0x00,
        0x00, 0x4e, 0x00,
        0x00, 0x4c, 0x03,
        0x00, 0x40, 0x44,
        0x00, 0x00, 0x00,
        0x00, 0x00, 0x00,
        0x00, 0x00, 0x00,
        
        0xab, 0xab, 0xab,
        0x12, 0x60, 0xce,
        0x3d, 0x42, 0xfa,
        0x6e, 0x29, 0xfa,
        0x99, 0x1c, 0xce,
        0xb1, 0x1e, 0x81,
        0xb1, 0x2f, 0x29,
        0x99, 0x4a, 0x00,
        0x6e, 0x69, 0x00,
        0x3d, 0x82, 0x00,
        0x12, 0x8f, 0x00,
        0x00, 0x8d, 0x29,
        0x00, 0x7c, 0x81,
        0x00, 0x00, 0x00,
        0x00, 0x00, 0x00,
        0x00, 0x00, 0x00,
        
        0xff, 0xff, 0xff,
        0x60, 0xb2, 0xff,
        0x8d, 0x92, 0xff,
        0xc0, 0x78, 0xff,
        0xec, 0x6a, 0xff,
        0xff, 0x6d, 0xd4,
        0xff, 0x7f, 0x79,
        0xec, 0x9b, 0x2a,
        0xc0, 0xba, 0x00,
        0x8d, 0xd4, 0x00,
        0x60, 0xe2, 0x2a,
        0x47, 0xe0, 0x79,
        0x47, 0xce, 0xd4,
        0x4e, 0x4e, 0x4e,
        0x00, 0x00, 0x00,
        0x00, 0x00, 0x00,
        
        0xff, 0xff, 0xff,
        0xbf, 0xe0, 0xff,
        0xd1, 0xd3, 0xff,
        0xe6, 0xc9, 0xff,
        0xf7, 0xc3, 0xff,
        0xff, 0xc4, 0xee,
        0xff, 0xcb, 0xc9,
        0xf7, 0xd7, 0xa9,
        0xe6, 0xe3, 0x97,
        0xd1, 0xee, 0x97,
        0xbf, 0xf3, 0xa9,
        0xb5, 0xf2, 0xc9,
        0xb5, 0xeb, 0xee,
        0xb8, 0xb8, 0xb8,
        0x00, 0x00, 0x00,
        0x00, 0x00, 0x00
    ]
    
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
                getPalette(at: 0)
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
    
    private func getPalette(at index: Int) -> Color {
        let effectiveIndex = index * 3
        
        guard effectiveIndex + 2 < palette.count else {
            if index == 0 {
                return Color(white: 0x62 / 255)
            } else {
                return getPalette(at: 0)
            }
        }
        
        let r = palette[effectiveIndex * 3]
        let g = palette[effectiveIndex * 3 + 1]
        let b = palette[effectiveIndex  + 2]
        
        return Color(
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255
        )
    }
    
    private func draw() {
        guard let data = nes.frame else {
            return
        }
        
        palette.withUnsafeBytes({ buffer in
            guard let palettePtr = buffer.bindMemory(to: u8.self).baseAddress,
                  let colorSpace = CGColorSpace(
                    indexedBaseSpace: CGColorSpaceCreateDeviceRGB(),
                    last: 63, // palette of 64 colors
                    colorTable: palettePtr
                  ),
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
        })
    }
}

#Preview {
    NESView(Data())
}
