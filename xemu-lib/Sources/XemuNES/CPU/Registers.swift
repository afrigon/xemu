import XemuFoundation

extension MOS6502 {
    struct Registers: Codable {
        
        /// Accumulator Register
        var a: u8 = 0
        
        /// X Index Register
        var x: u8 = 0
        
        /// Y Index Register
        var y: u8 = 0
        
        /// Stack Pointer Register
        var s: u8 = 0x00
        
        /// Program Counter Register
        var pc: u16 = 0xFFFC
        
        /// Program Status Register
        var p: Flags = .init()
    }
}
