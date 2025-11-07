import XemuFoundation

// 7  bit  0
// ---- ----
// VSOx xxxx
// |||| ||||
// |||+-++++- (PPU open bus or 2C05 PPU identifier)
// ||+------- Sprite overflow flag
// |+-------- Sprite 0 hit flag
// +--------- Vblank flag, cleared on read. Unreliable

struct PPUStatusRegister: Codable {
    var spriteOverflow: Bool = false
    var sprite0Hit: Bool = false
    var verticalBlank: Bool = false
    
    var value: u8 {
        return (
            ((spriteOverflow ? 0xff : 0x00) & 0b0010_0000) |
            ((sprite0Hit     ? 0xff : 0x00) & 0b0100_0000) |
            ((verticalBlank  ? 0xff : 0x00) & 0b1000_0000)
        )
    }
}
