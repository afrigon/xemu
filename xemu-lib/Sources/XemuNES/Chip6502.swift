public class Chip6502: Codable {
    enum State: Codable {
        case initial
        case fetching
    }
    
    enum Mnemonic: String {
        case ADC
        case AND
        case ASL
        case BCC
        case BCS
        case BEQ
        case BIT
        case BMI
        case BNE
        case BPL
        case BRK
        case BVC
        case BVS
        case CLC
        case CLD
        case CLI
        case CLV
        case CMP
        case CPX
        case CPY
        case DEC
        case DEX
        case DEY
        case EOR
        case INC
        case INX
        case INY
        case JMP
        case JSR
        case LDA
        case LDX
        case LDY
        case LSR
        case NOP
        case ORA
        case PHA
        case PHP
        case PLA
        case PLP
        case ROL
        case ROR
        case RTI
        case RTS
        case SBC
        case SEC
        case SED
        case SEI
        case STA
        case STX
        case STY
        case TAX
        case TAY
        case TSX
        case TXA
        case TXS
        case TYA
    }
    
    enum AddressingMode {
        enum Index {
            case x
            case y
        }
        
        case implied
        case accumulator
        case immediate
        case relative
        case zeroPage(Index?)
        case absolute(Index?)
        case indirect(Index?)
        
        static var zeroPage: AddressingMode { .zeroPage(nil) }
        static var absolute: AddressingMode { .absolute(nil) }
        static var indirect: AddressingMode { .indirect(nil) }
    }
    
    struct Instruction {
        let mnemonic: Mnemonic
        let addressingMode: AddressingMode
    }
    
    /// Accumulator Register
    var a: UInt8 = 0
    
    /// X Index Register
    var x: UInt8 = 0
    
    /// Y Index Register
    var y: UInt8 = 0
    
    /// Stack Pointer Register
    var s: UInt8 = 0xFD
    
    /// Program Counter Register
    var pc: UInt16 = 0xFFFC

    /// Program Status Register
    var p: UInt8 = 0b0010_0100
    
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

    private let instructions: [Instruction?] = [
        Instruction(mnemonic: .BRK, addressingMode: .implied),      // $00
        Instruction(mnemonic: .ORA, addressingMode: .indirect(.x)), // $01
        nil,                                                        // $02
        nil,                                                        // $03
        nil,                                                        // $04
        Instruction(mnemonic: .ORA, addressingMode: .zeroPage),     // $05
        Instruction(mnemonic: .ASL, addressingMode: .zeroPage),     // $06
        nil,                                                        // $07
        Instruction(mnemonic: .PHP, addressingMode: .implied),      // $08
        Instruction(mnemonic: .ORA, addressingMode: .immediate),    // $09
        Instruction(mnemonic: .ASL, addressingMode: .accumulator),  // $0A
        nil,                                                        // $0B
        nil,                                                        // $0C
        Instruction(mnemonic: .ORA, addressingMode: .absolute),     // $0D
        Instruction(mnemonic: .ASL, addressingMode: .absolute),     // $0E
        nil,                                                        // $0F
        Instruction(mnemonic: .BPL, addressingMode: .relative),     // $10
        Instruction(mnemonic: .ORA, addressingMode: .indirect(.y)), // $11
        nil,                                                        // $12
        nil,                                                        // $13
        nil,                                                        // $14
        Instruction(mnemonic: .ORA, addressingMode: .zeroPage(.x)), // $15
        Instruction(mnemonic: .ASL, addressingMode: .zeroPage(.x)), // $16
        nil,                                                        // $17
        Instruction(mnemonic: .CLC, addressingMode: .implied),      // $18
        Instruction(mnemonic: .ORA, addressingMode: .absolute(.y)), // $19
        nil,                                                        // $1A
        nil,                                                        // $1B
        nil,                                                        // $1C
        Instruction(mnemonic: .ORA, addressingMode: .absolute(.x)), // $1D
        Instruction(mnemonic: .ASL, addressingMode: .absolute(.x)), // $1E
        nil,                                                        // $1F
        Instruction(mnemonic: .JSR, addressingMode: .absolute),     // $20
        Instruction(mnemonic: .AND, addressingMode: .indirect(.x)), // $21
        nil,                                                        // $22
        nil,                                                        // $23
        Instruction(mnemonic: .BIT, addressingMode: .zeroPage),     // $24
        Instruction(mnemonic: .AND, addressingMode: .zeroPage),     // $25
        Instruction(mnemonic: .ROL, addressingMode: .zeroPage),     // $26
        nil,                                                        // $27
        Instruction(mnemonic: .PLP, addressingMode: .implied),      // $28
        Instruction(mnemonic: .AND, addressingMode: .immediate),    // $29
        Instruction(mnemonic: .ROL, addressingMode: .accumulator),  // $2A
        nil,                                                        // $2B
        Instruction(mnemonic: .BIT, addressingMode: .absolute),     // $2C
        Instruction(mnemonic: .AND, addressingMode: .absolute),     // $2D
        Instruction(mnemonic: .ROL, addressingMode: .absolute),     // $2E
        nil,                                                        // $2F
        Instruction(mnemonic: .BMI, addressingMode: .relative),     // $30
        Instruction(mnemonic: .AND, addressingMode: .indirect(.y)), // $31
        nil,                                                        // $32
        nil,                                                        // $33
        nil,                                                        // $34
        Instruction(mnemonic: .AND, addressingMode: .zeroPage(.x)), // $35
        Instruction(mnemonic: .ROL, addressingMode: .zeroPage(.x)), // $36
        nil,                                                        // $37
        Instruction(mnemonic: .SEC, addressingMode: .implied),      // $38
        Instruction(mnemonic: .AND, addressingMode: .absolute(.y)), // $39
        nil,                                                        // $3A
        nil,                                                        // $3B
        nil,                                                        // $3C
        Instruction(mnemonic: .AND, addressingMode: .absolute(.x)), // $3D
        Instruction(mnemonic: .ROL, addressingMode: .absolute(.x)), // $3E
        nil,                                                        // $3F
        Instruction(mnemonic: .RTI, addressingMode: .implied),      // $40
        Instruction(mnemonic: .EOR, addressingMode: .indirect(.x)), // $41
        nil,                                                        // $42
        nil,                                                        // $43
        nil,                                                        // $44
        Instruction(mnemonic: .EOR, addressingMode: .zeroPage),     // $45
        Instruction(mnemonic: .LSR, addressingMode: .zeroPage),     // $46
        nil,                                                        // $47
        Instruction(mnemonic: .PHA, addressingMode: .implied),      // $48
        Instruction(mnemonic: .EOR, addressingMode: .immediate),    // $49
        Instruction(mnemonic: .LSR, addressingMode: .accumulator),  // $4A
        nil,                                                        // $4B
        Instruction(mnemonic: .JMP, addressingMode: .absolute),     // $4C
        Instruction(mnemonic: .EOR, addressingMode: .absolute),     // $4D
        Instruction(mnemonic: .LSR, addressingMode: .absolute),     // $4E
        nil,                                                        // $4F
        Instruction(mnemonic: .BVC, addressingMode: .relative),     // $50
        Instruction(mnemonic: .EOR, addressingMode: .indirect(.y)), // $51
        nil,                                                        // $52
        nil,                                                        // $53
        nil,                                                        // $54
        Instruction(mnemonic: .EOR, addressingMode: .zeroPage(.x)), // $55
        Instruction(mnemonic: .LSR, addressingMode: .zeroPage(.x)), // $56
        nil,                                                        // $57
        Instruction(mnemonic: .CLI, addressingMode: .implied),      // $58
        Instruction(mnemonic: .EOR, addressingMode: .absolute(.y)), // $59
        nil,                                                        // $5A
        nil,                                                        // $5B
        nil,                                                        // $5C
        Instruction(mnemonic: .EOR, addressingMode: .absolute(.x)), // $5D
        Instruction(mnemonic: .LSR, addressingMode: .absolute(.x)), // $5E
        nil,                                                        // $5F
        Instruction(mnemonic: .RTS, addressingMode: .implied),      // $60
        Instruction(mnemonic: .ADC, addressingMode: .indirect(.x)), // $61
        nil,                                                        // $62
        nil,                                                        // $63
        nil,                                                        // $64
        Instruction(mnemonic: .ADC, addressingMode: .zeroPage),     // $65
        Instruction(mnemonic: .ROR, addressingMode: .zeroPage),     // $66
        nil,                                                        // $67
        Instruction(mnemonic: .PLA, addressingMode: .implied),      // $68
        Instruction(mnemonic: .ADC, addressingMode: .immediate),    // $69
        Instruction(mnemonic: .ROR, addressingMode: .accumulator),  // $6A
        nil,                                                        // $6B
        Instruction(mnemonic: .JMP, addressingMode: .indirect),     // $6C
        Instruction(mnemonic: .ADC, addressingMode: .absolute),     // $6D
        Instruction(mnemonic: .ROR, addressingMode: .absolute),     // $6E
        nil,                                                        // $6F
        Instruction(mnemonic: .BVS, addressingMode: .relative),     // $70
        Instruction(mnemonic: .ADC, addressingMode: .indirect(.y)), // $71
        nil,                                                        // $72
        nil,                                                        // $73
        nil,                                                        // $74
        Instruction(mnemonic: .ADC, addressingMode: .zeroPage(.x)), // $75
        Instruction(mnemonic: .ROR, addressingMode: .zeroPage(.x)), // $76
        nil,                                                        // $77
        Instruction(mnemonic: .SEI, addressingMode: .implied),      // $78
        Instruction(mnemonic: .ADC, addressingMode: .absolute(.y)), // $79
        nil,                                                        // $7A
        nil,                                                        // $7B
        nil,                                                        // $7C
        Instruction(mnemonic: .ADC, addressingMode: .absolute(.x)), // $7D
        Instruction(mnemonic: .ROR, addressingMode: .absolute(.x)), // $7E
        nil,                                                        // $7F
        nil,                                                        // $80
        Instruction(mnemonic: .STA, addressingMode: .indirect(.x)), // $81
        nil,                                                        // $82
        nil,                                                        // $83
        Instruction(mnemonic: .STY, addressingMode: .zeroPage),     // $84
        Instruction(mnemonic: .STA, addressingMode: .zeroPage),     // $85
        Instruction(mnemonic: .STX, addressingMode: .zeroPage),     // $86
        nil,                                                        // $87
        Instruction(mnemonic: .DEY, addressingMode: .implied),      // $88
        nil,                                                        // $89
        Instruction(mnemonic: .TXA, addressingMode: .implied),      // $8A
        nil,                                                        // $8B
        Instruction(mnemonic: .STY, addressingMode: .absolute),     // $8C
        Instruction(mnemonic: .STA, addressingMode: .absolute),     // $8D
        Instruction(mnemonic: .STX, addressingMode: .absolute),     // $8E
        nil,                                                        // $8F
        Instruction(mnemonic: .BCC, addressingMode: .relative),     // $90
        Instruction(mnemonic: .STA, addressingMode: .indirect(.y)), // $91
        nil,                                                        // $92
        nil,                                                        // $93
        Instruction(mnemonic: .STY, addressingMode: .zeroPage(.x)), // $94
        Instruction(mnemonic: .STA, addressingMode: .zeroPage(.x)), // $95
        Instruction(mnemonic: .STX, addressingMode: .zeroPage(.y)), // $96
        nil,                                                        // $97
        Instruction(mnemonic: .TYA, addressingMode: .implied),      // $98
        Instruction(mnemonic: .STA, addressingMode: .absolute(.y)), // $99
        Instruction(mnemonic: .TXS, addressingMode: .implied),      // $9A
        nil,                                                        // $9B
        nil,                                                        // $9C
        Instruction(mnemonic: .STA, addressingMode: .absolute(.x)), // $9D
        nil,                                                        // $9E
        nil,                                                        // $9F
        Instruction(mnemonic: .LDY, addressingMode: .immediate),    // $A0
        Instruction(mnemonic: .LDA, addressingMode: .indirect(.x)), // $A1
        Instruction(mnemonic: .LDX, addressingMode: .immediate),    // $A2
        nil,                                                        // $A3
        Instruction(mnemonic: .LDY, addressingMode: .zeroPage),     // $A4
        Instruction(mnemonic: .LDA, addressingMode: .zeroPage),     // $A5
        Instruction(mnemonic: .LDX, addressingMode: .zeroPage),     // $A6
        nil,                                                        // $A7
        Instruction(mnemonic: .TAY, addressingMode: .implied),      // $A8
        Instruction(mnemonic: .LDA, addressingMode: .immediate),    // $A9
        Instruction(mnemonic: .TAX, addressingMode: .implied),      // $AA
        nil,                                                        // $AB
        Instruction(mnemonic: .LDY, addressingMode: .absolute),     // $AC
        Instruction(mnemonic: .LDA, addressingMode: .absolute),     // $AD
        Instruction(mnemonic: .LDX, addressingMode: .absolute),     // $AE
        nil,                                                        // $AF
        Instruction(mnemonic: .BCS, addressingMode: .relative),     // $B0
        Instruction(mnemonic: .LDA, addressingMode: .indirect(.y)), // $B1
        nil,                                                        // $B2
        nil,                                                        // $B3
        Instruction(mnemonic: .LDY, addressingMode: .zeroPage(.x)), // $B4
        Instruction(mnemonic: .LDA, addressingMode: .zeroPage(.x)), // $B5
        Instruction(mnemonic: .LDX, addressingMode: .zeroPage(.y)), // $B6
        nil,                                                        // $B7
        Instruction(mnemonic: .CLV, addressingMode: .implied),      // $B8
        Instruction(mnemonic: .LDA, addressingMode: .absolute(.y)), // $B9
        Instruction(mnemonic: .TSX, addressingMode: .implied),      // $BA
        nil,                                                        // $BB
        Instruction(mnemonic: .LDY, addressingMode: .absolute(.x)), // $BC
        Instruction(mnemonic: .LDA, addressingMode: .absolute(.x)), // $BD
        Instruction(mnemonic: .LDX, addressingMode: .absolute(.y)), // $BE
        nil,                                                        // $BF
        Instruction(mnemonic: .CPY, addressingMode: .immediate),    // $C0
        Instruction(mnemonic: .CMP, addressingMode: .indirect(.x)), // $C1
        nil,                                                        // $C2
        nil,                                                        // $C3
        Instruction(mnemonic: .CPY, addressingMode: .zeroPage),     // $C4
        Instruction(mnemonic: .CMP, addressingMode: .zeroPage),     // $C5
        Instruction(mnemonic: .DEC, addressingMode: .zeroPage),     // $C6
        nil,                                                        // $C7
        Instruction(mnemonic: .INY, addressingMode: .implied),      // $C8
        Instruction(mnemonic: .CMP, addressingMode: .immediate),    // $C9
        Instruction(mnemonic: .DEX, addressingMode: .implied),      // $CA
        nil,                                                        // $CB
        Instruction(mnemonic: .CPY, addressingMode: .absolute),     // $CC
        Instruction(mnemonic: .CMP, addressingMode: .absolute),     // $CD
        Instruction(mnemonic: .DEC, addressingMode: .absolute),     // $CE
        nil,                                                        // $CF
        Instruction(mnemonic: .BNE, addressingMode: .relative),     // $D0
        Instruction(mnemonic: .CMP, addressingMode: .indirect(.y)), // $D1
        nil,                                                        // $D2
        nil,                                                        // $D3
        nil,                                                        // $D4
        Instruction(mnemonic: .CMP, addressingMode: .zeroPage(.x)), // $D5
        Instruction(mnemonic: .DEC, addressingMode: .zeroPage(.x)), // $D6
        nil,                                                        // $D7
        Instruction(mnemonic: .CLD, addressingMode: .implied),      // $D8
        Instruction(mnemonic: .CMP, addressingMode: .absolute(.y)), // $D9
        nil,                                                        // $DA
        nil,                                                        // $DB
        nil,                                                        // $DC
        Instruction(mnemonic: .CMP, addressingMode: .absolute(.x)), // $DD
        Instruction(mnemonic: .DEC, addressingMode: .absolute(.x)), // $DE
        nil,                                                        // $DF
        Instruction(mnemonic: .CPX, addressingMode: .immediate),    // $E0
        Instruction(mnemonic: .SBC, addressingMode: .indirect(.x)), // $E1
        nil,                                                        // $E2
        nil,                                                        // $E3
        Instruction(mnemonic: .CPX, addressingMode: .zeroPage),     // $E4
        Instruction(mnemonic: .SBC, addressingMode: .zeroPage),     // $E5
        Instruction(mnemonic: .INC, addressingMode: .zeroPage),     // $E6
        nil,                                                        // $E7
        Instruction(mnemonic: .INX, addressingMode: .implied),      // $E8
        Instruction(mnemonic: .SBC, addressingMode: .immediate),    // $E9
        Instruction(mnemonic: .NOP, addressingMode: .implied),      // $EA
        nil,                                                        // $EB
        Instruction(mnemonic: .CPX, addressingMode: .absolute),     // $EC
        Instruction(mnemonic: .SBC, addressingMode: .absolute),     // $ED
        Instruction(mnemonic: .INC, addressingMode: .absolute),     // $EE
        nil,                                                        // $EF
        Instruction(mnemonic: .BEQ, addressingMode: .relative),     // $F0
        Instruction(mnemonic: .SBC, addressingMode: .indirect(.y)), // $F1
        nil,                                                        // $F2
        nil,                                                        // $F3
        nil,                                                        // $F4
        Instruction(mnemonic: .SBC, addressingMode: .zeroPage(.x)), // $F5
        Instruction(mnemonic: .INC, addressingMode: .zeroPage(.x)), // $F6
        nil,                                                        // $F7
        Instruction(mnemonic: .SED, addressingMode: .implied),      // $F8
        Instruction(mnemonic: .SBC, addressingMode: .absolute(.y)), // $F9
        nil,                                                        // $FA
        nil,                                                        // $FB
        nil,                                                        // $FC
        Instruction(mnemonic: .SBC, addressingMode: .absolute(.x)), // $FD
        Instruction(mnemonic: .INC, addressingMode: .absolute(.x)), // $FE
        nil                                                         // $FF
    ]
    
    weak var bus: Bus!
    
    private var state: State = .initial
    
    init(bus: Bus) {
        self.bus = bus
    }

    /// Sets the given flags to 1 in the program status register
    private func setFlags(_ flags: UInt8) {
        p |= flags
    }
    
    /// Sets the given flags to 0 in the program status register
    private func clearFlags(_ flags: UInt8) {
        p &= ~flags
    }
    
    /// Runs for exactly 1 cycle
    public func clock() {
        
    }
    
    /// Reset Signal
    public func reset() {
        
    }
    
    /// Non-maskable Interrupt
    public func nmi() {
        
    }
    
    /// Interrupt Request
    public func irq() {
        
    }
    
    enum CodingKeys: CodingKey {
        case a
        case x
        case y
        case s
        case pc
        case p
        case state
    }
}
