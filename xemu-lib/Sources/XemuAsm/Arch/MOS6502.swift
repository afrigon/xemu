import XemuFoundation

public struct MOS6502 {
    public enum Instruction: AsmConvertible, BytecodeConvertible {
        case adc(AddressingMode)
        case and(AddressingMode)
        case asl(AddressingMode)
        case bcc(AddressingMode)
        case bcs(AddressingMode)
        case beq(AddressingMode)
        case bit(AddressingMode)
        case bmi(AddressingMode)
        case bne(AddressingMode)
        case bpl(AddressingMode)
        case brk
        case bvc(AddressingMode)
        case bvs(AddressingMode)
        case clc
        case cli
        case cld
        case clv
        case cmp(AddressingMode)
        case cpx(AddressingMode)
        case cpy(AddressingMode)
        case dec(AddressingMode)
        case dex
        case dey
        case eor(AddressingMode)
        case inc(AddressingMode)
        case inx
        case iny
        case jmp(AddressingMode)
        case jsr(AddressingMode)
        case lda(AddressingMode)
        case ldx(AddressingMode)
        case ldy(AddressingMode)
        case lsr(AddressingMode)
        case nop
        case ora(AddressingMode)
        case pha
        case php
        case pla
        case plp
        case rol(AddressingMode)
        case ror(AddressingMode)
        case rti
        case rts
        case sbc(AddressingMode)
        case sec
        case sed
        case sei
        case sta(AddressingMode)
        case stx(AddressingMode)
        case sty(AddressingMode)
        case tax
        case tay
        case tsx
        case txa
        case txs
        case tya
        case bad
        
        var bytes: [u8] {
            switch self {
                case .adc(.immediate(let x)): [0x69]
                case .adc(.zeroPage(let x)): [0x65, x]
                case .adc(.zeroPageX(let x)): [0x75, x]
                case .adc(.absolute(let x)): [0x6D] + x.p16()
                case .adc(.absoluteX(let x)): [0x7D] + x.p16()
                case .adc(.absoluteY(let x)): [0x79] + x.p16()
                case .adc(.indexedIndirect(let x)): [0x61, x]
                case .adc(.indirectIndexed(let x)): [0x71, x]
                    
                case .and(.immediate(let x)): [0x29]
                case .and(.zeroPage(let x)): [0x25, x]
                case .and(.zeroPageX(let x)): [0x35, x]
                case .and(.absolute(let x)): [0x2D] + x.p16()
                case .and(.absoluteX(let x)): [0x3D] + x.p16()
                case .and(.absoluteY(let x)): [0x39] + x.p16()
                case .and(.indexedIndirect(let x)): [0x21, x]
                case .and(.indirectIndexed(let x)): [0x31, x]
                    
                case .asl(.accumulator): [0x0A]
                case .asl(.zeroPage(let x)): [0x06, x]
                case .asl(.zeroPageX(let x)): [0x16, x]
                case .asl(.absolute(let x)): [0x0E] + x.p16()
                case .asl(.absoluteX(let x)): [0x1E] + x.p16()
                    
                case .bit(.zeroPage(let x)): [0x24, x]
                case .bit(.absolute(let x)): [0x2C] + x.p16()
                    
                case .brk: [0x00]
                    
                case .bcc(.relative(let x)): [0x90, u8(bitPattern: x)]
                case .bcs(.relative(let x)): [0xB0, u8(bitPattern: x)]
                case .beq(.relative(let x)): [0xF0, u8(bitPattern: x)]
                case .bmi(.relative(let x)): [0x30, u8(bitPattern: x)]
                case .bne(.relative(let x)): [0xD0, u8(bitPattern: x)]
                case .bpl(.relative(let x)): [0x10, u8(bitPattern: x)]
                case .bvc(.relative(let x)): [0x50, u8(bitPattern: x)]
                case .bvs(.relative(let x)): [0x70, u8(bitPattern: x)]
                    
                case .clc: [0x18]
                case .cld: [0xD8]
                case .cli: [0x58]
                case .clv: [0xB8]
                    
                case .cmp(.immediate(let x)): [0xC9, x]
                case .cmp(.zeroPage(let x)): [0xC5, x]
                case .cmp(.zeroPageX(let x)): [0xD5, x]
                case .cmp(.absolute(let x)): [0xCD] + x.p16()
                case .cmp(.absoluteX(let x)): [0xDD] + x.p16()
                case .cmp(.absoluteY(let x)): [0xD9] + x.p16()
                case .cmp(.indexedIndirect(let x)): [0xC1, x]
                case .cmp(.indirectIndexed(let x)): [0xD1, x]
                    
                case .cpx(.immediate(let x)): [0xE0, x]
                case .cpx(.zeroPage(let x)): [0xE4, x]
                case .cpx(.absolute(let x)): [0xEC] + x.p16()
                    
                case .cpy(.immediate(let x)): [0xC0, x]
                case .cpy(.zeroPage(let x)): [0xC4, x]
                case .cpy(.absolute(let x)): [0xCC] + x.p16()
                    
                case .dec(.zeroPage(let x)): [0xC6, x]
                case .dec(.zeroPageX(let x)): [0xD6, x]
                case .dec(.absolute(let x)): [0xCE] + x.p16()
                case .dec(.absoluteX(let x)): [0xDE] + x.p16()
                case .dex: [0xCA]
                case .dey: [0x88]
                    
                case .eor(.immediate(let x)): [0x49, x]
                case .eor(.zeroPage(let x)): [0x45, x]
                case .eor(.zeroPageX(let x)): [0x55, x]
                case .eor(.absolute(let x)): [0x4D] + x.p16()
                case .eor(.absoluteX(let x)): [0x5D] + x.p16()
                case .eor(.absoluteY(let x)): [0x59] + x.p16()
                case .eor(.indexedIndirect(let x)): [0x41, x]
                case .eor(.indirectIndexed(let x)): [0x51, x]
                    
                case .inc(.zeroPage(let x)): [0xE6, x]
                case .inc(.zeroPageX(let x)): [0xF6, x]
                case .inc(.absolute(let x)): [0xEE] + x.p16()
                case .inc(.absoluteX(let x)): [0xFE] + x.p16()
                case .inx: [0xE8]
                case .iny: [0xC8]
                    
                case .jmp(.absolute(let x)): [0x4C] + x.p16()
                case .jmp(.indirect(let x)): [0x6C] + x.p16()
                case .jsr(.absolute(let x)): [0x20] + x.p16()
                    
                case .lda(.immediate(let x)): [0xA9, x]
                case .lda(.zeroPage(let x)): [0xA5, x]
                case .lda(.zeroPageX(let x)): [0xB5, x]
                case .lda(.absolute(let x)): [0xAD] + x.p16()
                case .lda(.absoluteX(let x)): [0xBD] + x.p16()
                case .lda(.absoluteY(let x)): [0xB9] + x.p16()
                case .lda(.indexedIndirect(let x)): [0xA1, x]
                case .lda(.indirectIndexed(let x)): [0xB1, x]
                    
                case .ldx(.immediate(let x)): [0xA2, x]
                case .ldx(.zeroPage(let x)): [0xA6, x]
                case .ldx(.zeroPageY(let x)): [0xB6, x]
                case .ldx(.absolute(let x)): [0xAE] + x.p16()
                case .ldx(.absoluteY(let x)): [0xBE] + x.p16()
                    
                case .ldy(.immediate(let x)): [0xA0, x]
                case .ldy(.zeroPage(let x)): [0xA4, x]
                case .ldy(.zeroPageX(let x)): [0xB4, x]
                case .ldy(.absolute(let x)): [0xAC] + x.p16()
                case .ldy(.absoluteX(let x)): [0xBC] + x.p16()
                    
                case .lsr(.accumulator): [0x4A]
                case .lsr(.zeroPage(let x)): [0x46, x]
                case .lsr(.zeroPageX(let x)): [0x56, x]
                case .lsr(.absolute(let x)): [0x4E] + x.p16()
                case .lsr(.absoluteX(let x)): [0x5E] + x.p16()
                    
                case .nop: [0xEA]
                    
                case .ora(.immediate(let x)): [0x09, x]
                case .ora(.zeroPage(let x)): [0x05, x]
                case .ora(.zeroPageX(let x)): [0x15, x]
                case .ora(.absolute(let x)): [0x0D] + x.p16()
                case .ora(.absoluteX(let x)): [0x1D] + x.p16()
                case .ora(.absoluteY(let x)): [0x19] + x.p16()
                case .ora(.indexedIndirect(let x)): [0x01, x]
                case .ora(.indirectIndexed(let x)): [0x11, x]
                    
                case .pha: [0x48]
                case .php: [0x08]
                case .pla: [0x68]
                case .plp: [0x28]
                    
                case .rol(.accumulator): [0x2A]
                case .rol(.zeroPage(let x)): [0x26, x]
                case .rol(.zeroPageX(let x)): [0x36, x]
                case .rol(.absolute(let x)): [0x2E] + x.p16()
                case .rol(.absoluteX(let x)): [0x3E] + x.p16()
                    
                case .ror(.accumulator): [0x6A]
                case .ror(.zeroPage(let x)): [0x66, x]
                case .ror(.zeroPageX(let x)): [0x76, x]
                case .ror(.absolute(let x)): [0x6E] + x.p16()
                case .ror(.absoluteX(let x)): [0x7E] + x.p16()
                    
                case .rti: [0x40]
                case .rts: [0x60]
                    
                case .sbc(.immediate(let x)): [0xE9, x]
                case .sbc(.zeroPage(let x)): [0xE5, x]
                case .sbc(.zeroPageX(let x)): [0xF5, x]
                case .sbc(.absolute(let x)): [0xED] + x.p16()
                case .sbc(.absoluteX(let x)): [0xFD] + x.p16()
                case .sbc(.absoluteY(let x)): [0xF9] + x.p16()
                case .sbc(.indexedIndirect(let x)): [0xE1, x]
                case .sbc(.indirectIndexed(let x)): [0xF1, x]
                    
                case .sec: [0x38]
                case .sed: [0xF8]
                case .sei: [0x78]
                    
                case .sta(.zeroPage(let x)): [0x85, x]
                case .sta(.zeroPageX(let x)): [0x95, x]
                case .sta(.absolute(let x)): [0x8D] + x.p16()
                case .sta(.absoluteX(let x)): [0x9D] + x.p16()
                case .sta(.absoluteY(let x)): [0x99] + x.p16()
                case .sta(.indexedIndirect(let x)): [0x81, x]
                case .sta(.indirectIndexed(let x)): [0x91, x]
                    
                case .stx(.zeroPage(let x)): [0x86, x]
                case .stx(.zeroPageY(let x)): [0x96, x]
                case .stx(.absolute(let x)): [0x8E] + x.p16()
                    
                case .sty(.zeroPage(let x)): [0x84, x]
                case .sty(.zeroPageX(let x)): [0x94, x]
                case .sty(.absolute(let x)): [0x8C] + x.p16()
   
                case .tax: [0xAA]
                case .tay: [0xA8]
                case .tsx: [0xBA]
                case .txa: [0x8A]
                case .txs: [0x9A]
                case .tya: [0x98]
                default: []
            }
        }
        
        public func asm(offset: Int) -> String {
            switch self {
                case .adc(let addressingMode):
                    "adc \(addressingMode.asm(offset: offset))"
                case .and(let addressingMode):
                    "adc \(addressingMode.asm(offset: offset))"
                case .asl(let addressingMode):
                    "asl \(addressingMode.asm(offset: offset))"
                case .bcc(let addressingMode):
                    "bcc \(addressingMode.asm(offset: offset))"
                case .bcs(let addressingMode):
                    "bcs \(addressingMode.asm(offset: offset))"
                case .beq(let addressingMode):
                    "beq \(addressingMode.asm(offset: offset))"
                case .bit(let addressingMode):
                    "bit \(addressingMode.asm(offset: offset))"
                case .bmi(let addressingMode):
                    "bmi \(addressingMode.asm(offset: offset))"
                case .bne(let addressingMode):
                    "bne \(addressingMode.asm(offset: offset))"
                case .bpl(let addressingMode):
                    "bpl \(addressingMode.asm(offset: offset))"
                case .brk:
                    "brk"
                case .bvc(let addressingMode):
                    "bvc \(addressingMode.asm(offset: offset))"
                case .bvs(let addressingMode):
                    "bvs \(addressingMode.asm(offset: offset))"
                case .clc:
                    "clc"
                case .cld:
                    "cld"
                case .cli:
                    "cli"
                case .clv:
                    "clv"
                case .cmp(let addressingMode):
                    "cmp \(addressingMode.asm(offset: offset))"
                case .cpx(let addressingMode):
                    "cpx \(addressingMode.asm(offset: offset))"
                case .cpy(let addressingMode):
                    "cpy \(addressingMode.asm(offset: offset))"
                case .dec(let addressingMode):
                    "dec \(addressingMode.asm(offset: offset))"
                case .dex:
                    "dex"
                case .dey:
                    "dey"
                case .eor(let addressingMode):
                    "eor \(addressingMode.asm(offset: offset))"
                case .inc(let addressingMode):
                    "inc \(addressingMode.asm(offset: offset))"
                case .inx:
                    "inx"
                case .iny:
                    "iny"
                case .jmp(let addressingMode):
                    "jmp \(addressingMode.asm(offset: offset))"
                case .jsr(let addressingMode):
                    "jsr \(addressingMode.asm(offset: offset))"
                case .lda(let addressingMode):
                    "lda \(addressingMode.asm(offset: offset))"
                case .ldx(let addressingMode):
                    "ldx \(addressingMode.asm(offset: offset))"
                case .ldy(let addressingMode):
                    "ldy \(addressingMode.asm(offset: offset))"
                case .lsr(let addressingMode):
                    "lsr \(addressingMode.asm(offset: offset))"
                case .nop:
                    "nop"
                case .ora(let addressingMode):
                    "ora \(addressingMode.asm(offset: offset))"
                case .pha:
                    "pha"
                case .php:
                    "php"
                case .pla:
                    "pla"
                case .plp:
                    "plp"
                case .rol(let addressingMode):
                    "rol \(addressingMode.asm(offset: offset))"
                case .ror(let addressingMode):
                    "ror \(addressingMode.asm(offset: offset))"
                case .rti:
                    "rti"
                case .rts:
                    "rts"
                case .sbc(let addressingMode):
                    "sbc \(addressingMode.asm(offset: offset))"
                case .sec:
                    "sec"
                case .sed:
                    "sed"
                case .sei:
                    "sei"
                case .sta(let addressingMode):
                    "sta \(addressingMode.asm(offset: offset))"
                case .stx(let addressingMode):
                    "stx \(addressingMode.asm(offset: offset))"
                case .sty(let addressingMode):
                    "sty \(addressingMode.asm(offset: offset))"
                case .tax:
                    "tax"
                case .tay:
                    "tay"
                case .tsx:
                    "tsx"
                case .txa:
                    "txa"
                case .txs:
                    "txs"
                case .tya:
                    "tya"
                case .bad:
                    "bad"
            }
        }
    }
    
    public enum AddressingMode: AsmConvertible {
        case accumulator
        case immediate(u8)
        case relative(i8)
        
        case zeroPage(u8)
        case zeroPageX(u8)
        case zeroPageY(u8)
        
        case absolute(u16)
        case absoluteX(u16)
        case absoluteY(u16)
        
        case indirect(u16)
        case indexedIndirect(u8)
        case indirectIndexed(u8)
        
        public func asm(offset: Int) -> String {
            switch self {
                case .accumulator:
                    ""
                case .immediate(let value):
                    value.hex(prefix: "#$", toLength: 2, textCase: .lowercase)
                case .relative(let value):
                    (offset + Int(value)).hex(prefix: "$", toLength: 4, textCase: .lowercase)
                case .zeroPage(let value):
                    value.hex(prefix: "$", toLength: 2, textCase: .lowercase)
                case .zeroPageX(let value):
                    value.hex(prefix: "$", toLength: 2, textCase: .lowercase) + ", x"
                case .zeroPageY(let value):
                    value.hex(prefix: "$", toLength: 2, textCase: .lowercase) + ", y"
                case .absolute(let address):
                    address.hex(prefix: "$", toLength: 4, textCase: .lowercase)
                case .absoluteX(let address):
                    address.hex(prefix: "$", toLength: 4, textCase: .lowercase) + ", x"
                case .absoluteY(let address):
                    address.hex(prefix: "$", toLength: 4, textCase: .lowercase) + ", y"
                case .indirect(let value):
                    "(\(value.hex(prefix: "$", toLength: 2, textCase: .lowercase)))"
                case .indexedIndirect(let value):
                    "(\(value.hex(prefix: "$", toLength: 2, textCase: .lowercase)), x)"
                case .indirectIndexed(let value):
                    "(\(value.hex(prefix: "$", toLength: 2, textCase: .lowercase))), y"
            }
        }
    }
}
