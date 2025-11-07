// 7  bit  0
// ---- ----
// BGRs bMmG
// |||| ||||
// |||| |||+- Greyscale (0: normal color, 1: greyscale)
// |||| ||+-- 1: Show background in leftmost 8 pixels of screen, 0: Hide
// |||| |+--- 1: Show sprites in leftmost 8 pixels of screen, 0: Hide
// |||| +---- 1: Enable background rendering
// |||+------ 1: Enable sprite rendering
// ||+------- Emphasize red (green on PAL/Dendy)
// |+-------- Emphasize green (red on PAL/Dendy)
// +--------- Emphasize blue

struct PPUMaskRegister: Codable {
    var grayscale: Bool = false
    var backgroundMask: Bool = false
    var spritesMask: Bool = false
    var backgroundEnabled: Bool = false
    var spritesEnabled: Bool = false
    var emphasizeRed: Bool = false
    var emphasizeGreen: Bool = false
    var emphasizeBlue: Bool = false
}
