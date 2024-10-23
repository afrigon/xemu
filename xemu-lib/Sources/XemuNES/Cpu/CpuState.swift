import XemuFoundation

class CpuState: Codable {
    var tick: u8 = 0
    var opcode: u8 = 0
    var lo: u8 = 0
    var hi: u8 = 0
    var temp: u8 = 0
    var halt: Bool = false
    
    var data: u16 {
        get {
            u16(hi) << 8 | u16(lo)
        }
        set {
            let bytes = newValue.p16()
            lo = bytes[0]
            hi = bytes[1]
        }
    }
}
