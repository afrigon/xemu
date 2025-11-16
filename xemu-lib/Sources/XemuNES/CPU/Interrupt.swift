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
    
    func handleOAMDMA() {
        state.oamdmaTick -= 1
        
        if state.oamdmaTick == 0 {
            state.oamdmaActive = false
        }
        
        switch state.oamdmaTick {
            case 512, 513:
                break
            case _ where Bool(state.oamdmaTick & 1):
                let address = state.oamdmaPage | ((511 - state.oamdmaTick) / 2)
                state.oamdmaTemp = bus.read(at: address)
            case _ where !Bool(state.oamdmaTick & 1):
                bus.write(state.oamdmaTemp, at: 0x2004)
            default:
                break
        }
    }
    
    func handleInterrupt() {
        peek8()
        state.opcode = 0x00
        
        peek8()
        push16(registers.pc)
        
        if state.nmiPending {
            state.nmiPending = false
            push8(registers.p.value(b: false))
            registers.p.interruptDisabled = true
            registers.pc = read16(at: InterruptType.nmi.rawValue)
        } else {
            push8(registers.p.value(b: false))
            registers.p.interruptDisabled = true
            registers.pc = read16(at: InterruptType.irq.rawValue)
        }
    }
    
    /// Force Interrupt
    /// The BRK instruction forces the generation of an interrupt request.
    /// The program counter and processor status are pushed on the stack then
    /// the IRQ interrupt vector at $FFFE/F is loaded into the PC and the break
    /// flag in the status set to one
    func brk() {
        peek8()
        push16(registers.pc &+ 1)

        if state.nmiPending {
            state.nmiPending = false
            push8(registers.p.value(b: true))
            registers.p.interruptDisabled = true
            registers.pc = read16(at: InterruptType.nmi.rawValue)
        } else {
            push8(registers.p.value(b: true))
            registers.p.interruptDisabled = true
            registers.pc = read16(at: InterruptType.irq.rawValue)
        }
        
        state.nmiOldPending = false
    }

    /// Return from Interrupt
    /// The RTI instruction is used at the end of an interrupt processing routine.
    /// It pulls the processor flags from the stack followed by the program counter
    func rti() {
        peek8()
        registers.p.set(pop8())
        registers.pc = pop16()
    }
}
