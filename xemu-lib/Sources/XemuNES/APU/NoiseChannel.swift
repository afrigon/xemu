import XemuFoundation

struct NoiseChannel: Codable {
    var envelope: Envelope = .init()
    var lengthCounter: LengthCounter = .init()

    mutating func clock() {
        
    }

    func output() -> u8 {
        0
    }
}
