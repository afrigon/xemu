import SwiftUI
import XemuNES
import XemuFoundation

extension Palette {
    func color(for index: Int) -> Color {
        let c: (r: u8, g: u8, b: u8) = color(for: index)
        
        return Color(
            red: Double(c.r) / 255,
            green: Double(c.g) / 255,
            blue: Double(c.b) / 255
        )
    }
    
    var colorSpace: CGColorSpace? {
        data.withUnsafeBytes({ buffer in
            guard let palettePtr = buffer.bindMemory(to: u8.self).baseAddress,
                  let colorSpace = CGColorSpace(
                    indexedBaseSpace: CGColorSpaceCreateDeviceRGB(),
                    last: data.count - 1,
                    colorTable: palettePtr
                  ) else {
                return nil
            }
            
            return colorSpace
        })
    }
}
