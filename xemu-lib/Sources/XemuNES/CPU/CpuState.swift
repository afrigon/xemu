import XemuFoundation

extension MOS6502 {
    struct CpuState: Codable {
        var opcode: u8 = 0
        
        // Interrupt
        var irqSignal: Bool = false
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
    }
}
