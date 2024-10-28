import XemuDebugger
import XemuFoundation

public class MOS6502: Codable {
    var registers = Registers()
    var state = CpuState()
    
    weak var bus: Bus!
    
    private lazy var unimplementedHandler = AddressingModeHandler(
        read: handleUnimplementedRead,
        modify: handleUnimplementedModify,
        write: handleUnimplementedWrite
    )
    
    private lazy var accumulatorHandler = AddressingModeHandler(
        read: handleUnimplementedRead,
        modify: handleAccumulatorModify,
        write: handleUnimplementedWrite
    )
    
    private lazy var immediateHandler = AddressingModeHandler(
        read: handleImmediateRead,
        modify: handleUnimplementedModify,
        write: ignoreImmediateWrite
    )

    private lazy var absoluteHandler = AddressingModeHandler(
        read: handleAbsoluteRead,
        modify: handleAbsoluteModify,
        write: handleAbsoluteWrite
    )
    
    private lazy var absoluteIndexedXHandler = AddressingModeHandler(
        read: handleAbsoluteIndexedXRead,
        modify: handleAbsoluteIndexedXModify,
        write: handleAbsoluteIndexedXWrite
    )
    
    private lazy var absoluteIndexedYHandler = AddressingModeHandler(
        read: handleAbsoluteIndexedYRead,
        modify: handleAbsoluteIndexedYModify,
        write: handleAbsoluteIndexedYWrite
    )
    
    private lazy var zeroPageHandler = AddressingModeHandler(
        read: handleZeroPageRead,
        modify: handleZeroPageModify,
        write: handleZeroPageWrite
    )
    
    private lazy var zeroPageIndexedXHandler = AddressingModeHandler(
        read: handleZeroPageIndexedXRead,
        modify: handleZeroPageIndexedXModify,
        write: handleZeroPageIndexedXWrite
    )
    
    private lazy var zeroPageIndexedYHandler = AddressingModeHandler(
        read: handleZeroPageIndexedYRead,
        modify: handleZeroPageIndexedYModify,
        write: handleZeroPageIndexedYWrite
    )
    
    private lazy var indirectIndexedHandler = AddressingModeHandler(
        read: handleIndirectIndexedRead,
        modify: handleIndirectIndexedModify,
        write: handleIndirectIndexedWrite
    )
    
    private lazy var indexedIndirectHandler = AddressingModeHandler(
        read: handleIndexedIndirectRead,
        modify: handleIndexedIndirectModify,
        write: handleIndexedIndirectWrite
    )

    init(bus: Bus) {
        self.bus = bus
    }
    
    @inline(__always) func read8() -> u8 {
        defer { registers.pc &+= 1 }
        
        return bus.read(at: registers.pc)
    }
    
    @inline(__always) func push(_ value: u8) {
        bus.writeStack(value, at: registers.s)
        registers.s &-= 1
    }
    
   @inline(__always) func pop() -> u8 {
        registers.s &+= 1
        return bus.readStack(at: registers.s)
    }
    
    func pollInterrupts() {
        state.oldNmiPending = state.nmiPending
        
        let oldNMI = state.nmiLastValue
        state.nmiLastValue = bus.nmiSignal()
        
        if state.nmiLastValue && !oldNMI {
            state.nmiPending = true
        }
        
        state.irqPending = bus.irqSignal()
    }

    /// Runs for exactly 1 cycle
    public func clock() throws(XemuError) {
        guard !state.halted else {
            throw .emulatorHalted
        }
        
        state.tick += 1
        
        if state.tick == 1 {
            if state.oldNmiPending {
                state.servicing = .nmi
            } else if state.irqPending {
                state.servicing = .irq
            }
        }
        
        // TODO: disable polling when taking a branch? https://www.nesdev.org/wiki/CPU_interrupts#Branch_instructions_and_interrupts
        pollInterrupts()

        switch state.servicing {
            case .some(.irq), .some(.nmi):
                return handleInterrupt()
            case .some(.reset):
                return handleReset()
            default:
                break
        }
        
        if state.tick == 1 {
            
            // fetch
            state.opcode = read8()
        } else {
            
            // decode
            // https://llx.com/Neil/a2/opcodes.html
            let groupIndex          = (state.opcode & 0b0000_0011)
            let addressingModeIndex = (state.opcode & 0b0001_1100) >> 2
            let opcodeIndex         = (state.opcode & 0b1110_0000) >> 5
            
            switch groupIndex {
                case 0b01:
                    handleGroupOne(addressingIndex: addressingModeIndex, opcodeIndex: opcodeIndex)
                case 0b10:
                    handleGroupTwo(addressingIndex: addressingModeIndex, opcodeIndex: opcodeIndex)
                case 0b00:
                    try handleGroupThree()
                case 0b11:
                    handleUnofficial(addressingIndex: addressingModeIndex, opcodeIndex: opcodeIndex)
                default:
                    fatalError("Impossible to reach this state")
            }
        }
    }
    
    // Group One instructions are primarily arithmetic instrucions.
    private func handleGroupOne(addressingIndex: u8, opcodeIndex: u8) {
        let addressingMode = switch addressingIndex {
            case 0b000:
                indexedIndirectHandler
            case 0b001:
                zeroPageHandler
            case 0b010:
                immediateHandler
            case 0b011:
                absoluteHandler
            case 0b100:
                indirectIndexedHandler
            case 0b101:
                zeroPageIndexedXHandler
            case 0b110:
                absoluteIndexedYHandler
            case 0b111:
                absoluteIndexedXHandler
            default:
                unimplementedHandler
        }
        
        switch opcodeIndex {
            case 0b000:
                addressingMode.read(ora)
            case 0b001:
                addressingMode.read(and)
            case 0b010:
                addressingMode.read(eor)
            case 0b011:
                addressingMode.read(adc)
            case 0b100:
                addressingMode.write(sta)
            case 0b101:
                addressingMode.read(lda)
            case 0b110:
                addressingMode.read(cmp)
            case 0b111:
                addressingMode.read(sbc)
            default:
                break
        }
    }
    
    // Group Two instructions are primarily Read, Modify, Write instructions
    private func handleGroupTwo(addressingIndex: u8, opcodeIndex: u8) {
        switch state.opcode {
            case 0x82, 0xC2, 0xE2: immediateHandler.read(nopRead)
            case 0x1A, 0x3A, 0x5A, 0x7A, 0xDA, 0xEA, 0xFA: handleImplied(nop)
            // unofficial instructions that will cause problems
            case 0x02, 0x22, 0x42, 0x62, 0x12, 0x32, 0x52, 0x72, 0x92, 0xB2, 0xD2, 0xF2: halt()
            case 0xA2: immediateHandler.read(ldx)
            case 0x8A: handleImplied(txa)
            case 0xAA: handleImplied(tax)
            case 0xCA: handleImplied(dex)
            case 0x9A: handleImplied(txs)
            case 0xBA: handleImplied(tsx)
            case 0x96: zeroPageIndexedYHandler.write(stx)
            case 0xB6: zeroPageIndexedYHandler.read(ldx)
            case 0xBE: absoluteIndexedYHandler.read(ldx)
            case 0x9E: absoluteIndexedYHandler.write(shx)
            default:
                let addressingMode = switch addressingIndex {
                    case 0b001: zeroPageHandler
                    case 0b010: accumulatorHandler
                    case 0b011: absoluteHandler
                    case 0b101: zeroPageIndexedXHandler
                    case 0b111: absoluteIndexedXHandler
                    default: unimplementedHandler
                }

                switch opcodeIndex {
                    case 0b000: addressingMode.modify(asl)
                    case 0b001: addressingMode.modify(rol)
                    case 0b010: addressingMode.modify(lsr)
                    case 0b011: addressingMode.modify(ror)
                    case 0b100: addressingMode.write(stx)
                    case 0b101: addressingMode.read(ldx)
                    case 0b110: addressingMode.modify(dec)
                    case 0b111: addressingMode.modify(inc)
                    default: break
                }
        }
    }
    
    // All the branch instructions, flag operations, stack operations, and a few others.
    private func handleGroupThree() throws(XemuError) {
        
        // Branch instructions are of the form xxy10000
        if state.opcode & 0b0001_1111 == 0b0001_0000 {
            return branch()
        }
        
        switch state.opcode {
            case 0x00: brk()
            case 0x80: immediateHandler.read(nopRead)
            case 0x04, 0x44, 0x64: zeroPageHandler.read(nopRead)
            case 0x0C: absoluteHandler.read(nopRead)
            case 0x14, 0x34, 0x54, 0x74, 0xD4, 0xF4: zeroPageIndexedXHandler.read(nopRead)
            case 0x1C, 0x3C, 0x5C, 0x7C, 0xDC, 0xFC: absoluteIndexedXHandler.read(nopRead)
            case 0x9C: absoluteIndexedXHandler.write(shy)
            case 0xA0: immediateHandler.read(ldy)
            case 0xC0: immediateHandler.read(cpy)
            case 0xE0: immediateHandler.read(cpx)
            case 0x24: zeroPageHandler.read(bit)
            case 0x84: zeroPageHandler.write(sty)
            case 0xA4: zeroPageHandler.read(ldy)
            case 0xC4: zeroPageHandler.read(cpy)
            case 0xE4: zeroPageHandler.read(cpx)
            case 0x2C: absoluteHandler.read(bit)
            case 0x8C: absoluteHandler.write(sty)
            case 0xAC: absoluteHandler.read(ldy)
            case 0xCC: absoluteHandler.read(cpy)
            case 0xEC: absoluteHandler.read(cpx)
            case 0x94: zeroPageIndexedXHandler.write(sty)
            case 0xB4: zeroPageIndexedXHandler.read(ldy)
            case 0xBC: absoluteIndexedXHandler.read(ldy)
            case 0x4C: jmpAbsolute()
            case 0x6C: jmpIndirect()
            case 0x20: jsr()
            case 0x08: php()
            case 0x28: plp()
            case 0x48: pha()
            case 0x68: pla()
            case 0x40: rti()
            case 0x60: try rts()
            case 0x88: handleImplied(dey)
            case 0xA8: handleImplied(tay)
            case 0xC8: handleImplied(iny)
            case 0xE8: handleImplied(inx)
            case 0x18: handleImplied(clc)
            case 0xD8: handleImplied(cld)
            case 0x58: handleImplied(cli)
            case 0xB8: handleImplied(clv)
            case 0x38: handleImplied(sec)
            case 0xF8: handleImplied(sed)
            case 0x78: handleImplied(sei)
            case 0x98: handleImplied(tya)
            default: break
        }
    }
    
    // https://www.nesdev.org/wiki/CPU_unofficial_opcodes
    private func handleUnofficial(addressingIndex: u8, opcodeIndex: u8) {
        switch state.opcode {
            case 0x0B, 0x2B: immediateHandler.read(anc)
            case 0x4B: immediateHandler.read(alr)
            case 0x6B: immediateHandler.read(arr)
            case 0x8B: immediateHandler.read(xaa)
            case 0x93: indirectIndexedHandler.write(ahx)
            case 0x9B: absoluteIndexedYHandler.write(tas)
            case 0x97: zeroPageIndexedYHandler.write(sax)
            case 0x9F: absoluteIndexedYHandler.write(ahx)
            case 0xB7: zeroPageIndexedYHandler.read(lax)
            case 0xBB: absoluteIndexedYHandler.read(las)
            case 0xBF: absoluteIndexedYHandler.read(lax)
            case 0xCB: immediateHandler.read(axs)
            case 0xEB: immediateHandler.read(sbc)
            default:
                let addressingMode = switch addressingIndex {
                    case 0b000: indexedIndirectHandler
                    case 0b001: zeroPageHandler
                    case 0b010: immediateHandler
                    case 0b011: absoluteHandler
                    case 0b100: indirectIndexedHandler
                    case 0b101: zeroPageIndexedXHandler
                    case 0b110: absoluteIndexedYHandler
                    case 0b111: absoluteIndexedXHandler
                    default: unimplementedHandler
                }

                switch opcodeIndex {
                    case 0b000: addressingMode.modify(slo)
                    case 0b001: addressingMode.modify(rla)
                    case 0b010: addressingMode.modify(sre)
                    case 0b011: addressingMode.modify(rra)
                    case 0b100: addressingMode.write(sax)
                    case 0b101: addressingMode.read(lax)
                    case 0b110: addressingMode.modify(dcp)
                    case 0b111: addressingMode.modify(isc)
                    default: break
                }
        }
    }
    
    enum CodingKeys: String, CodingKey {
        case registers
        case state
    }
}

extension MOS6502 {
    public func getRegisters() -> [RegisterInfo] {
        [
            .regular("A", size: 1, value: .u8(registers.a)),
            .regular("X", size: 1, value: .u8(registers.x)),
            .regular("Y", size: 1, value: .u8(registers.y)),
            .stack("S", size: 1, value: .u8(registers.s)),
            .programCounter("PC", size: 2, value: .u16(registers.pc)),
            .flags(
                "P",
                size: 1,
                flags: [
                    .init(mask: UInt(Flags.CARRY_MASK), acronym: "C", name: "Carry"),
                    .init(mask: UInt(Flags.ZERO_MASK), acronym: "Z", name: "Zero"),
                    .init(mask: UInt(Flags.INTERRUPT_DISABLED_MASK), acronym: "I", name: "Interrupt"),
                    .init(mask: UInt(Flags.DECIMAL_MASK), acronym: "D", name: "Decimal"),
                    .init(mask: 0b0001_0000, acronym: "B", name: "Break"),
                    .init(mask: 0b0010_0000, acronym: "1", name: "Always"),
                    .init(mask: UInt(Flags.OVERFLOW_MASK), acronym: "V", name: "Overflow"),
                    .init(mask: UInt(Flags.NEGATIVE_MASK), acronym: "N", name: "Negative"),
                ],
                value: .u8(registers.p.value())
            )
        ]
    }
    
    public func setRegister(name: String, value: u64) {
        switch name.uppercased() {
            case "A":
                registers.a = u8(value & 0xff)
            case "X":
                registers.x = u8(value & 0xff)
            case "Y":
                registers.y = u8(value & 0xff)
            case "S":
                registers.s = u8(value & 0xff)
            case "PC":
                registers.pc = u16(value & 0xffff)
            case "P":
                registers.p = .init(u8(value & 0xff))
            default:
                print("Unknown register: \(name) = \(value)")
        }
    }
}
