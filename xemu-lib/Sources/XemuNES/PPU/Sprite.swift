import XemuFoundation

struct Sprite {
    var mirror: Bool = false
    var backgroundPriority: Bool = false
    var x: u8 = 0
    var lo: u8 = 0
    var hi: u8 = 0
    var paletteOffset: u8 = 0
}
