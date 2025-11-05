import XemuNES
import SwiftUI
import stylx
import XemuFoundation

struct NESPatternTableView: View {
    @State var images: [CGImage] = []

    let iNes: iNesFile
    
    let palette: [u8] = [
//        0x0F, 0x12, 0x37, 0x16
//        0x0F, 0x2A, 0x17, 0x37
        0x00, 0x00, 0x00, 0x40
    ]

    init(iNes: iNesFile) {
        self.iNes = iNes
    }
    
    var body: some View {
        VStack {
            TabView {
                ForEach(images, id: \.self) { image in
                    Image(platformImage: PlatformImage(cgImage: image, size: .init(width: 128, height: 128)))
                        .resizable()
                        .interpolation(.none)
                        .aspectRatio(contentMode: .fit)
                }
            }
#if os(iOS)
            .tabViewStyle(.page)
            .indexViewStyle(.page(backgroundDisplayMode: .always))
#endif
            .onAppear {
                let banks = decodeBanks()
                images = banks.compactMap { generateImage($0) }
            }
            
            NESPaletteView(palette: .default)
        }
    }
    
    private func decodeBanks() -> [[u8]] {
        var chrDecoredBanks: [[u8]] = []

        for i in 0..<Int(iNes.chrromSize) {
            var chrDecoredBank: [u8] = .init(repeating: 0, count: 256 * 16 * 8)
            
            for row in 0..<16 {
                for col in 0..<16 {
                    let tileStart = i * 0x1000 + row * 256 + col * 16
                    let pixelStart = (row * 128 * 8) + col * 8

                    for y in 0..<8 {
                        let index = tileStart + y
                        var plane0 = iNes.chrrom[index]
                        var plane1 = iNes.chrrom[index + 8]
                        
                        for x in 0..<8 {
                            let i = pixelStart + (y * 128) + (7 - x)
                            chrDecoredBank[i] = palette[Int(((plane0 & 1) | (plane1 & 1) << 1))]
                            plane0 >>= 1
                            plane1 >>= 1
                        }
                    }
                }
            }
            
            chrDecoredBanks.append(chrDecoredBank)
        }
        
        return chrDecoredBanks
    }
    
    private func generateImage(_ data: [u8]) -> CGImage? {
        guard let colorSpace = Palette.default.colorSpace,
              let provider = CGDataProvider(data: Data(data) as CFData) else {
            return nil
        }
        
        return CGImage(
            width: 128,
            height: 128,
            bitsPerComponent: 8,
            bitsPerPixel: 8,
            bytesPerRow: 128,
            space: colorSpace,
            bitmapInfo: CGBitmapInfo(rawValue: CGImageAlphaInfo.none.rawValue),
            provider: provider,
            decode: nil,
            shouldInterpolate: false,
            intent: .defaultIntent
        )!
    }
}
