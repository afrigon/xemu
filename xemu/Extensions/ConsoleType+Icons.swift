import XemuCore
import SwiftUI

extension ConsoleType {
    public var icon: ImageResource {
        return switch self {
            case .nes:
                .nes
            case .snes:
                .snes
            case .gb:
                .gb
            case .gbc:
                .gbc
            case .gba:
                .gba
            case .n64:
                .n64
            case .ds:
                .nds
            case .gc:
                .gc
            case .wii:
                .nes
            case .dc:
                .dc
            case .gen:
                .gen
        }
    }
}
