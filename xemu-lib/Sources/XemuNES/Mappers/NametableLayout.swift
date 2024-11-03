import XemuFoundation

/// Hard-wired nametable layout
public enum NametableLayout: Codable {
    
    /// Vertical arrangement ("mirrored horizontally") or mapper-controlled
    case vertical
    
    /// Horizontal arrangement ("mirrored vertically")
    case horizontal
    
    case oneScreenLower
    case oneScreenUpper

    /// Alternative Nametables
    /// https://www.nesdev.org/wiki/NES_2.0#Nametable_layout
    case other
    
    var OFFSET_0: u16 { 0x0000 }
    var OFFSET_1: u16 { 0x0400 }
    var OFFSET_2: u16 { 0x0800 }
    var OFFSET_3: u16 { 0x0C00 }
    
    init(_ value: Bool, alternative: Bool) {
        if alternative {
            self = .other
        } else {
            if value {
                self = .horizontal
            } else {
                self = .vertical
            }
        }
    }
    
    func map(_ address: u16) -> u16 {
        switch self {
            case .horizontal:
                map(
                    address: address,
                    upperLeft: OFFSET_0,
                    upperRight: OFFSET_0,
                    lowerLeft: OFFSET_1,
                    lowerRight: OFFSET_1
                )
            case .vertical:
                map(
                    address: address,
                    upperLeft: OFFSET_0,
                    upperRight: OFFSET_1,
                    lowerLeft: OFFSET_0,
                    lowerRight: OFFSET_1
                )
            case .oneScreenLower:
                map(
                    address: address,
                    upperLeft: OFFSET_0,
                    upperRight: OFFSET_0,
                    lowerLeft: OFFSET_0,
                    lowerRight: OFFSET_0
                )
            case .oneScreenUpper:
                map(
                    address: address,
                    upperLeft: OFFSET_1,
                    upperRight: OFFSET_1,
                    lowerLeft: OFFSET_1,
                    lowerRight: OFFSET_1
                )
            default:
                address & 0x0FFF
        }
    }
    
    private func map(
        address: u16,
        upperLeft: u16,
        upperRight: u16,
        lowerLeft: u16,
        lowerRight: u16
    ) -> u16 {
        switch address & 0x0FFF {
            case 0x0000...0x03FF: address & 0x3FF + upperLeft
            case 0x0400...0x07FF: address & 0x3FF + upperRight
            case 0x0800...0x0BFF: address & 0x3FF + lowerLeft
            case 0x0C00...0x0FFF: address & 0x3FF + lowerRight
            default: 0
        }
    }
}
