import SwiftUI
import XemuNES
import XemuFoundation

struct NESPaletteView: View {
    let palette: Palette
    
    init(palette: Palette) {
        self.palette = palette
    }
    
    var body: some View {
        GeometryReader { geometry in
            let size = geometry.size.width / 16
            
            LazyVGrid(columns: [.init(.adaptive(minimum: size), spacing: .zero)], spacing: .zero) {
                ForEach(0..<(palette.data.count / 3), id: \.self) { index in
                    palette.color(for: Int(index))
                        .frame(width: size, height: size)
                        .contextMenu {
                            let c: (r: u8, g: u8, b: u8) = palette.color(for: Int(index))
                            
                            Text(verbatim: "Index: \(index.hex(toLength: 2))")
                            Text(verbatim: "RGB: \(c.0) \(c.1) \(c.2)")
                        }
                }
            }
        }
    }
}

#Preview {
    NESPaletteView(palette: .default)
}
