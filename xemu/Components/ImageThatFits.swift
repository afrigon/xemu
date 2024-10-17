import SwiftUI
import stylx

public struct ImageThatFits: View {
    let image: PlatformImage
    let maxWidth: CGFloat
    let maxHeight: CGFloat
    
    public init?(_ data: Data, maxWidth: CGFloat, maxHeight: CGFloat) {
        guard let image = PlatformImage(data: data) else {
            return nil
        }
        
        self.image = image
        self.maxWidth = maxWidth
        self.maxHeight = maxHeight
    }
    
    public init?(_ data: Data, maxSize: CGFloat) {
        self.init(data, maxWidth: maxSize, maxHeight: maxSize)
    }
    
    public init(_ image: PlatformImage, maxWidth: CGFloat, maxHeight: CGFloat) {
        self.image = image
        self.maxWidth = maxWidth
        self.maxHeight = maxHeight
    }
    
    public init(_ image: PlatformImage, maxSize: CGFloat) {
        self.init(image, maxWidth: maxSize, maxHeight: maxSize)
    }

    public init?(_ image: Image, maxWidth: CGFloat, maxHeight: CGFloat) {
        guard let image = ImageRenderer(content: image).platformImage else {
            return nil
        }
        
        self.image = image
        self.maxWidth = maxWidth
        self.maxHeight = maxHeight
    }
    
    public init?(_ image: Image, maxSize: CGFloat) {
        self.init(image, maxWidth: maxSize, maxHeight: maxSize)
    }
    
    public var body: some View {
        Image(platformImage: image)
            .resizable()
            .aspectRatio(contentMode: .fit)
            .modify({ view in
                if image.size.width > image.size.height {
                    view.frame(maxWidth: maxWidth)
                } else {
                    view.frame(maxHeight: maxHeight)
                }
            })
    }
}

#Preview {
    HStack {
        ImageThatFits(
            PlatformImage(resource: .nesArtworkFront),
            maxWidth: .xxxxxxxl,
            maxHeight: .xxxxxxxl
        )
        
        ImageThatFits(
            PlatformImage(resource: .n64ArtworkFront),
            maxWidth: .xxxxxxxl,
            maxHeight: .xxxxxxxl
        )
    }
}
