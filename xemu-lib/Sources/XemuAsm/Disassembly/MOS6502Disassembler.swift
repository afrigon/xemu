import Foundation
import XemuFoundation

extension MOS6502 {
    public class Disassembler {
        let data: Data
        var pc: Int
        
        public init(data: Data) {
            self.data = data
            self.pc = 0x0000
        }
        
        public func disassemble(offset: Int = 0x0000) -> DisassemblyResult {
            var elements: [DisassemblyResult.Element] = []
            pc = 0

            while data.count > pc {
                let start = pc
                let opcode = read8()
                
                let instruction = decode(opcode)
                
                elements.append(.instruction(
                    address: offset + start,
                    raw: instruction.bytes,
                    value: instruction.asm(offset: start)
                ))
            }
            
            return .init(elements: elements)
        }
        
        private func read8() -> u8 {
            guard data.count > pc else {
                return 0
            }
            
            defer { pc += 1 }
            
            return data[pc]
        }
        
        private func read8Signed() -> i8 {
            return i8(bitPattern: read8())
        }

        private func read16() -> u16 {
            guard data.count > pc + 1 else {
                return 0
            }
            
            defer { pc += 2 }
            
            return [data[pc + 1], data[pc]].u16()
        }

        private func decode(_ opcode: u8) -> MOS6502.Instruction {
            return switch opcode {
                case 0x00: .brk
                case 0x01: .ora(.indexedIndirect(read8()))
                case 0x05: .ora(.zeroPage(read8()))
                case 0x06: .asl(.zeroPage(read8()))
                case 0x08: .php
                case 0x09: .ora(.immediate(read8()))
                case 0x0A: .asl(.accumulator)
                case 0x0D: .ora(.absolute(read16()))
                case 0x0E: .asl(.absolute(read16()))
                case 0x10: .bpl(.relative(read8Signed()))
                case 0x11: .ora(.indirectIndexed(read8()))
                case 0x15: .ora(.zeroPageX(read8()))
                case 0x16: .asl(.zeroPageX(read8()))
                case 0x18: .clc
                case 0x19: .ora(.absoluteY(read16()))
                case 0x1D: .ora(.absoluteX(read16()))
                case 0x1E: .asl(.absoluteX(read16()))
                case 0x20: .jsr(.absolute(read16()))
                case 0x21: .and(.indexedIndirect(read8()))
                case 0x24: .bit(.zeroPage(read8()))
                case 0x25: .and(.zeroPage(read8()))
                case 0x26: .rol(.zeroPage(read8()))
                case 0x28: .plp
                case 0x29: .and(.immediate(read8()))
                case 0x2A: .rol(.accumulator)
                case 0x2C: .bit(.absolute(read16()))
                case 0x2D: .and(.absolute(read16()))
                case 0x2E: .rol(.absolute(read16()))
                case 0x30: .bmi(.relative(read8Signed()))
                case 0x31: .and(.indirectIndexed(read8()))
                case 0x35: .and(.zeroPageX(read8()))
                case 0x36: .rol(.zeroPageX(read8()))
                case 0x38: .sec
                case 0x39: .and(.absoluteY(read16()))
                case 0x3D: .and(.absoluteX(read16()))
                case 0x3E: .rol(.absoluteX(read16()))
                case 0x40: .rti
                case 0x41: .eor(.indexedIndirect(read8()))
                case 0x45: .eor(.zeroPage(read8()))
                case 0x46: .lsr(.zeroPage(read8()))
                case 0x48: .pha
                case 0x49: .eor(.immediate(read8()))
                case 0x4A: .lsr(.accumulator)
                case 0x4C: .jmp(.absolute(read16()))
                case 0x4D: .eor(.absolute(read16()))
                case 0x4E: .lsr(.absolute(read16()))
                case 0x50: .bvc(.relative(read8Signed()))
                case 0x51: .eor(.indirectIndexed(read8()))
                case 0x55: .eor(.zeroPageX(read8()))
                case 0x56: .lsr(.zeroPageX(read8()))
                case 0x58: .cli
                case 0x59: .eor(.absoluteY(read16()))
                case 0x5D: .eor(.absoluteX(read16()))
                case 0x5E: .lsr(.absoluteX(read16()))
                case 0x60: .rts
                case 0x61: .adc(.indexedIndirect(read8()))
                case 0x65: .adc(.zeroPage(read8()))
                case 0x66: .ror(.zeroPage(read8()))
                case 0x68: .pla
                case 0x69: .adc(.immediate(read8()))
                case 0x6A: .ror(.accumulator)
                case 0x6C: .jmp(.indirect(read16()))
                case 0x6D: .adc(.absolute(read16()))
                case 0x6E: .ror(.absolute(read16()))
                case 0x70: .bvs(.relative(read8Signed()))
                case 0x71: .adc(.indirectIndexed(read8()))
                case 0x75: .adc(.zeroPageX(read8()))
                case 0x76: .ror(.zeroPageX(read8()))
                case 0x78: .sei
                case 0x79: .adc(.absoluteY(read16()))
                case 0x7D: .adc(.absoluteX(read16()))
                case 0x7E: .ror(.absoluteX(read16()))
                case 0x81: .sta(.indexedIndirect(read8()))
                case 0x84: .sty(.zeroPage(read8()))
                case 0x85: .sta(.zeroPage(read8()))
                case 0x86: .stx(.zeroPage(read8()))
                case 0x88: .dey
                case 0x8A: .txa
                case 0x8C: .sty(.absolute(read16()))
                case 0x8D: .sta(.absolute(read16()))
                case 0x8E: .stx(.absolute(read16()))
                case 0x90: .bcc(.relative(read8Signed()))
                case 0x91: .sta(.indirectIndexed(read8()))
                case 0x94: .sty(.zeroPageX(read8()))
                case 0x95: .sta(.zeroPageX(read8()))
                case 0x96: .stx(.zeroPageY(read8()))
                case 0x98: .tya
                case 0x99: .sta(.absoluteY(read16()))
                case 0x9A: .txs
                case 0x9D: .sta(.absoluteX(read16()))
                case 0xA0: .ldy(.immediate(read8()))
                case 0xA1: .lda(.indexedIndirect(read8()))
                case 0xA2: .ldx(.immediate(read8()))
                case 0xA4: .ldy(.zeroPage(read8()))
                case 0xA5: .lda(.zeroPage(read8()))
                case 0xA6: .ldx(.zeroPage(read8()))
                case 0xA8: .tay
                case 0xA9: .lda(.immediate(read8()))
                case 0xAA: .tax
                case 0xAC: .ldy(.absolute(read16()))
                case 0xAD: .lda(.absolute(read16()))
                case 0xAE: .ldx(.absolute(read16()))
                case 0xB0: .bcs(.relative(read8Signed()))
                case 0xB1: .lda(.indirectIndexed(read8()))
                case 0xB4: .ldy(.zeroPageX(read8()))
                case 0xB5: .lda(.zeroPageX(read8()))
                case 0xB6: .ldx(.zeroPageY(read8()))
                case 0xB8: .clv
                case 0xB9: .lda(.absoluteY(read16()))
                case 0xBA: .tsx
                case 0xBC: .ldy(.absoluteX(read16()))
                case 0xBD: .lda(.absoluteX(read16()))
                case 0xBE: .ldx(.absoluteY(read16()))
                case 0xC0: .cpy(.immediate(read8()))
                case 0xC1: .cmp(.indexedIndirect(read8()))
                case 0xC4: .cpy(.zeroPage(read8()))
                case 0xC5: .cmp(.zeroPage(read8()))
                case 0xC6: .dec(.zeroPage(read8()))
                case 0xC8: .iny
                case 0xC9: .cmp(.immediate(read8()))
                case 0xCA: .dex
                case 0xCC: .cpy(.absolute(read16()))
                case 0xCD: .cmp(.absolute(read16()))
                case 0xCE: .dec(.absolute(read16()))
                case 0xD0: .bne(.relative(read8Signed()))
                case 0xD1: .cmp(.indirectIndexed(read8()))
                case 0xD5: .cmp(.zeroPageX(read8()))
                case 0xD6: .dec(.zeroPageX(read8()))
                case 0xD8: .cld
                case 0xD9: .cmp(.absoluteY(read16()))
                case 0xDD: .cmp(.absoluteX(read16()))
                case 0xDE: .dec(.absoluteX(read16()))
                case 0xE0: .cpx(.immediate(read8()))
                case 0xE1: .sbc(.indexedIndirect(read8()))
                case 0xE4: .cpx(.zeroPage(read8()))
                case 0xE5: .sbc(.zeroPage(read8()))
                case 0xE6: .inc(.zeroPage(read8()))
                case 0xE8: .inx
                case 0xE9: .sbc(.immediate(read8()))
                case 0xEA: .nop
                case 0xEC: .cpx(.absolute(read16()))
                case 0xED: .sbc(.absolute(read16()))
                case 0xEE: .inc(.absolute(read16()))
                case 0xF0: .beq(.relative(read8Signed()))
                case 0xF1: .sbc(.indirectIndexed(read8()))
                case 0xF5: .sbc(.zeroPageX(read8()))
                case 0xF6: .inc(.zeroPageX(read8()))
                case 0xF8: .sed
                case 0xF9: .sbc(.absoluteY(read16()))
                case 0xFD: .sbc(.absoluteX(read16()))
                case 0xFE: .inc(.absoluteX(read16()))
                default: .bad
            }
        }
    }
}
