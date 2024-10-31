import XemuFoundation

struct LengthCounter: Codable {
    var enabled: Bool = false {
        didSet {
            if !enabled {
                value = 0
            }
        }
    }

    var halted: Bool = false
    var value: u8 = 0

    private static let table: [u8] = [
        10, 254, 20,  2, 40,  4, 80,  6, 160,   8, 60, 10, 14, 12, 26, 14,
        12,  16, 24, 18, 48, 20, 96, 22, 192,  24, 72, 26, 16, 28, 32, 30
    ]

    mutating func clock() {
        if !halted && value > 0 {
            value -= 1
        }
    }

    mutating func load(_ value: u8) {
        self.value = LengthCounter.table[Int(value)]
    }
}
