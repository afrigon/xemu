import XemuFoundation

extension MOS6502 {
    enum InterruptType: u16, Codable {
        
        /// Non-Maskable Interrupt triggered by ppu
        case nmi = 0xFFFA
        
        /// Triggered on reset button press and initial boot
        case reset = 0xFFFC
        
        /// Maskable Interrupt triggered by a brk instruction or by memory mappers
        case irq = 0xFFFE
    }
    
    func handleReset() {
        switch state.tick {
            case 1:
                bus.read(at: registers.pc)
                state.opcode = 0x00 // BRK
            case 2:
                bus.read(at: registers.pc)
            case 3:
                bus.read(at: u16(registers.s) + 0x0100)
                registers.s &-= 1
            case 4:
                bus.read(at: u16(registers.s) + 0x0100)
                registers.s &-= 1
            case 5:
                bus.read(at: u16(registers.s) + 0x0100)
                registers.s &-= 1
            case 6:
                state.lo = bus.read(at: InterruptType.reset.rawValue)
            case 7:
                state.hi = bus.read(at: InterruptType.reset.rawValue + 1)
                registers.pc = state.data
                state.tick = 0
                state.servicing = nil
            default:
                break
        }
    }

    func handleInterrupt() {
        switch state.tick {
            case 1:
                bus.read(at: registers.pc)
                state.opcode = 0x00  // BRK
            case 2:
                bus.read(at: registers.pc)
            case 3:
                push(u8(registers.pc >> 8))
            case 4:
                push(u8(registers.pc & 0xFF))
            case 5:
                if state.nmiRequested {
                    state.nmiRequested = false
                    state.data = InterruptType.nmi.rawValue
                } else {
                    state.data = InterruptType.irq.rawValue
                }
                push(registers.p.value(b: false))
            case 6:
                registers.pc = (registers.pc & 0xFF00) | u16(bus.read(at: state.data))
                registers.p.interruptDisabled = true
            case 7:
                registers.pc = (registers.pc & 0x00FF) | (u16(bus.read(at: state.data &+ 1)) << 8)
                state.tick = 0
                state.servicing = nil
            default:
                break
        }
    }
    
    /// Force Interrupt
    /// The BRK instruction forces the generation of an interrupt request.
    /// The program counter and processor status are pushed on the stack then
    /// the IRQ interrupt vector at $FFFE/F is loaded into the PC and the break
    /// flag in the status set to one
    func brk() {
        switch state.tick {
            case 2:
                _ = read8()
            case 3, 4:
                handleInterrupt()
            case 5:
                if state.nmiRequested {
                    state.nmiRequested = false
                    state.data = InterruptType.nmi.rawValue
                } else {
                    state.data = InterruptType.irq.rawValue
                }
                // the b flag is set to true even when the brk gets hijacked by an nmi
                push(registers.p.value(b: true))
            case 6, 7:
                handleInterrupt()
            default:
                break
        }
    }

    /// Return from Interrupt
    /// The RTI instruction is used at the end of an interrupt processing routine.
    /// It pulls the processor flags from the stack followed by the program counter
    func rti() {
        switch state.tick {
            case 2:
                bus.read(at: registers.pc)
            case 3:
                break
            case 4:
                registers.p.set(pop())
            case 5:
                state.lo = pop()
            case 6:
                state.hi = pop()
                registers.pc = state.data
                state.tick = 0
            default:
                break
        }
    }
}
