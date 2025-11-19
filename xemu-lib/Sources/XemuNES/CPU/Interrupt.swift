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
    
    func handleDma(_ address: u16) {
        guard state.needsDmaHalt else {
            return
        }
        
        let enableInternalRegisterRead = (address & 0xffe0) == 0x4000
        var skipFirstInputClock = false
        var previousAddress = address

        let skipDummyReads = address == 0x4016 || address == 0x4017
        
        if enableInternalRegisterRead && state.dmcDmaActive && skipDummyReads {
            let dmcAddress = bus.getDmcReadAddress()
            
            if dmcAddress & 0x1f == address & 0x1f {
                skipFirstInputClock = true
            }
        }
        
        state.needsDmaHalt = false
        
        startCycle(read: true)
        
        if state.dmcDmaAbort && skipDummyReads {
            
        } else if !skipFirstInputClock {
            bus.read(at: address)
        }
        
        endCycle(read: true)
        
        if state.dmcDmaAbort {
            state.dmcDmaActive = false
            state.dmcDmaAbort = false
            
            if !state.oamDmaActive {
                state.needsDmaDummyRead = false
                return
            }
        }
        
        var oamCounter: u16 = 0
        var oamAddress: u8 = 0
        var value: u8 = 0
        
        let cycle: () -> Void = { [weak self] in
            guard let self else {
                return
            }
            
            if self.state.dmcDmaAbort {
                self.state.dmcDmaActive = false
                self.state.dmcDmaAbort = false
                self.state.needsDmaDummyRead = false
                self.state.needsDmaHalt = false
            } else if self.state.needsDmaHalt {
                self.state.needsDmaHalt = false
            } else if self.state.needsDmaDummyRead {
                self.state.needsDmaDummyRead = false
            }
            
            startCycle(read: true)
        }
        
        while state.dmcDmaActive || state.oamDmaActive {
            let isGetCycle = self.cycles & 0x01 == 0
            
            if isGetCycle {
                if state.dmcDmaActive && !state.needsDmaHalt && !state.needsDmaDummyRead {
                    cycle()
                    
                    value = handleDmaRead(
                        at: bus.getDmcReadAddress(),
                        previousAddress: &previousAddress,
                        enableInternalRegisterReads: enableInternalRegisterRead
                    )
                    
                    endCycle(read: true)
                    state.dmcDmaActive = false
                    state.dmcDmaAbort = false
                    
                    // TODO: set apu dmc read buffer
                } else if state.oamDmaActive {
                    cycle()
                    
                    value = handleDmaRead(
                        at: u16(state.oamDmaOffset) &* 0x100 &+ u16(oamAddress),
                        previousAddress: &previousAddress,
                        enableInternalRegisterReads: enableInternalRegisterRead
                    )
                    
                    endCycle(read: true)
                    oamAddress &+= 1
                    oamCounter &+= 1
                } else {
                    assert(state.needsDmaHalt || state.needsDmaDummyRead)
                    cycle()
                    
                    if !skipDummyReads {
                        bus.read(at: address)
                    }
                    
                    endCycle(read: true)
                }
            } else {
                if state.oamDmaActive && Bool(oamCounter & 0x01) {
                    cycle()
                    bus.write(value, at: 0x2004)
                    endCycle(read: true)
                    
                    oamCounter &+= 1
                    
                    if oamCounter == 0x200 {
                        state.oamDmaActive = false
                    }
                } else {
                    cycle()
                    
                    if !skipDummyReads {
                        bus.read(at: address)
                    }
                    
                    endCycle(read: true)
                }
            }
        }
    }
    
    func handleDmaRead(at address: u16, previousAddress: inout u16, enableInternalRegisterReads: Bool) -> u8 {
        var value: u8
        
        if !enableInternalRegisterReads {
            if address >= 0x4000 && address <= 0x401f {
                value = 0 // TODO: replace with open bus
            } else {
                value = bus.read(at: address)
            }
            
            previousAddress = address
            
            return value
        } else {
            let internalAddress = 0x4000 | (address & 0x1f)
            let isSameAddress = internalAddress == address
            
            switch internalAddress {
                case 0x4015:
                    value = bus.read(at: internalAddress)
                    
                    if !isSameAddress {
                        bus.read(at: address)
                    }
                case 0x4016, 0x4017:
                    if previousAddress == internalAddress {
                        value = 0 // TODO: replace with open bus
                    } else {
                        value = bus.read(at: internalAddress)
                    }
                    
                    if !isSameAddress {
                        // TODO: figure out what should go in here
                    }
                default:
                    value = bus.read(at: address)
            }
            
            previousAddress = internalAddress
            
            return value
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
