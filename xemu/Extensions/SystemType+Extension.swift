import XemuCore
import SwiftUI

extension SystemType {
    public var customizationIdentifier: String {
        "app.frigon.xemu.\(rawValue)"
    }
    
    public var icon: ImageResource {
        switch self {
            case .nes:
                .nes
            case .superNes:
                .snes
            case .gameBoy:
                .gb
            case .gameBoyColor:
                .gbc
            case .gameBoyAdvance:
                .gba
            case .nintendo64:
                .n64
            case .DS:
                .nds
            case .gamecube:
                .gc
            case .wii:
                .wii
            case .wiiu:
                .wiiu
            case .switch:
                .sw
            case .dreamcast:
                .dc
            case .segaGenesis:
                .gen
        }
    }
    
    @MainActor
    public var smallIcon: Image? {
        // This is used in the iPad sidebar since I couldn't figure out how to resize the icons
        
        let renderer = ImageRenderer(content: Image(icon).resizable().frame(width: .xl, height: .xl))
        guard let image = renderer.platformImage else {
            return nil
        }
        
        return Image(platformImage: image)
    }
}
