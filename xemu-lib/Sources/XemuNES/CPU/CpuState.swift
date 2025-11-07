import XemuFoundation

extension MOS6502 {
    struct CpuState: Codable {
        var tick: u8 = 0
        var opcode: u8 = 0
        var lo: u8 = 0
        var hi: u8 = 0
        var temp: u8 = 0
        var isOddCycle: Bool = false
        
        // Interrupt
        var servicing: InterruptType? = nil
        
        var irqPending: Bool = false
        var irqOldPending: Bool = false
        
        var nmiPending: Bool = false
        var nmiOldPending: Bool = false
        var nmiSignal: Bool = false
        var nmiOldSignal: Bool = false

        var oamdmaActive: Bool = false
        var oamdmaPage: u16 = 0
        var oamdmaTick: u16 = 0
        var oamdmaTemp: u8 = 0

        var data: u16 {
            get {
                u16(hi) << 8 | u16(lo)
            }
            set {
                lo = u8(newValue & 0xFF)
                hi = u8(newValue >> 8)
            }
        }
    }
}
