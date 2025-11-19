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

        var dmcDmaActive: Bool = false
        var dmcDmaAbort: Bool = false
        var oamDmaActive: Bool = false
        var oamDmaOffset: u8 = 0
        var needsDmaDummyRead: Bool = false
        var needsDmaHalt: Bool = false
    }
}
