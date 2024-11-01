import XemuFoundation

struct NoiseChannel: Codable {
    var mode: Bool = false
    var loop: Bool = false
    var period: u16 = 0
    var timer: u16 = 0
    var shiftRegister: u16 = 1

    var envelope: Envelope = .init()
    var lengthCounter: LengthCounter = .init()
    
    static let periods: [u16] = [
        4, 8, 16, 32, 64, 96, 128, 160, 202, 254, 380, 508, 762, 1016, 2034, 4068
    ]

    mutating func clock() {
        guard timer == 0 else {
            return timer -= 1
        }
        
        timer = period
        
        let feedback = (shiftRegister & 1) ^ ((shiftRegister >> (mode ? 6 : 1)) & 1)
        shiftRegister = shiftRegister >> 1 | feedback << 14
    }

    func output() -> u8 {
        guard lengthCounter.value > 0 else {
            return 0
        }
        
        return u8(shiftRegister & 1) * envelope.value
    }
}
