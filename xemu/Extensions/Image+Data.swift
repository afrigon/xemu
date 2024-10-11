import SwiftUI

extension Image {
    init(data: Data) {
#if canImport(UIKit)
        self = Image(uiImage: UIImage(data: data) ?? UIImage())
#elseif canImport(AppKit)
        self = Image(nsImage: NSImage(data: data) ?? NSImage())
#else
        self = Image(systemImage: "square.fill")
#endif
    }
}
