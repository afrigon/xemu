import XemuFoundation

extension u16 {
    init(hi: u8, lo: u8) {
        self = u16(lo) | (u16(hi) << 8)
    }
}
