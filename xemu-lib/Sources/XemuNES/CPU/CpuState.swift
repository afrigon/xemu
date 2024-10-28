import XemuFoundation

extension MOS6502 {
    class CpuState: Codable {
        var tick: u8 = 0
        var opcode: u8 = 0
        var lo: u8 = 0
        var hi: u8 = 0
        var temp: u8 = 0
        var halted: Bool = false
        
        // Interrupt
        var servicing: InterruptType? = nil
        var irqPending: Bool = false
        var nmiPending: Bool = false
        var oldNmiPending: Bool = false
        var nmiLastValue: Bool = false
        
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
