import XemuFoundation

extension MOS6502 {
    struct Flags: Codable {
        var carry: Bool
        var zero: Bool
        var interruptDisabled: Bool
        var decimal: Bool
        var overflow: Bool
        var negative: Bool
        
        // 7  bit  0
        // ---- ----
        // NV1B DIZC
        // |||| ||||
        // |||| |||+- Carry
        // |||| ||+-- Zero
        // |||| |+--- Interrupt Disable
        // |||| +---- Decimal
        // |||+------ (No CPU effect; see: the B flag)
        // ||+------- (No CPU effect; always pushed as 1)
        // |+-------- Overflow
        // +--------- Negative
        
        static let CARRY_MASK: u8                  = 0b0000_0001
        static let ZERO_MASK: u8                   = 0b0000_0010
        static let INTERRUPT_DISABLED_MASK: u8     = 0b0000_0100
        static let DECIMAL_MASK: u8                = 0b0000_1000
        static let OVERFLOW_MASK: u8               = 0b0100_0000
        static let NEGATIVE_MASK: u8               = 0b1000_0000
        
        init(_ rawValue: u8 = 0b0010_0100) {
            carry               = Bool(rawValue & Flags.CARRY_MASK)
            zero                = Bool(rawValue & Flags.ZERO_MASK)
            interruptDisabled   = Bool(rawValue & Flags.INTERRUPT_DISABLED_MASK)
            decimal             = Bool(rawValue & Flags.DECIMAL_MASK)
            overflow            = Bool(rawValue & Flags.OVERFLOW_MASK)
            negative            = Bool(rawValue & Flags.NEGATIVE_MASK)
        }
        
        mutating func set(_ rawValue: u8) {
            carry               = Bool(rawValue & Flags.CARRY_MASK)
            zero                = Bool(rawValue & Flags.ZERO_MASK)
            interruptDisabled   = Bool(rawValue & Flags.INTERRUPT_DISABLED_MASK)
            decimal             = Bool(rawValue & Flags.DECIMAL_MASK)
            overflow            = Bool(rawValue & Flags.OVERFLOW_MASK)
            negative            = Bool(rawValue & Flags.NEGATIVE_MASK)
        }
        
        func value(b: Bool = false) -> u8 {
            u8(negative)            << 7 |
            u8(overflow)            << 6 |
            0b0010_0000                  |
            u8(b)                   << 4 |
            u8(decimal)             << 3 |
            u8(interruptDisabled)   << 2 |
            u8(zero)                << 1 |
            u8(carry)
        }
        
        mutating func setNZ(_ value: u8) {
            zero        = value == 0
            negative    = value & 0b1000_0000 != 0
        }
    }
}
