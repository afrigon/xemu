import SwiftUI
import stylx
import CoreImage.CIFilterBuiltins

public struct QRCodeView: View {
    @State var image: PlatformImage?
    
    let data: Data
    
    public init(_ data: Data) {
        self.data = data
    }
    
    public init?(_ data: String) {
        guard let data = data.data(using: .utf8) else {
            return nil
        }
        
        self.data = data
    }
    
    public init?(_ data: URL) {
        guard let data = data.absoluteString.data(using: .utf8) else {
            return nil
        }
        
        self.data = data
    }

    public var body: some View {
        GeometryReader { geometry in
            Color.red
                .overlay {
                    if let image {
                        Image(platformImage: image)
                            .resizable()
                            .interpolation(.none)
                            .frame(width: geometry.size.width, height: geometry.size.height)
                            .aspectRatio(contentMode: .fit)
                    }
                }
                .onAppear() {
                    image = generate()
                }
        }
    }
    
    private func generate() -> PlatformImage? {
        let context = CIContext()
        let filter = CIFilter.qrCodeGenerator()
        
        filter.message = data
        
        guard let outputImage = filter.outputImage,
              let cgImage = context.createCGImage(outputImage, from: outputImage.extent) else {
            return nil
        }
        
        return PlatformImage(cgImage: cgImage)
    }
}
